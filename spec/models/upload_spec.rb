require 'rails_helper'

RSpec.describe Upload, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  subject { FactoryBot.create(:upload, storage_provider: mocked_storage_provider) }

  let(:completed_upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, storage_provider: mocked_storage_provider) }
  let(:upload_with_error) { FactoryBot.create(:upload, :with_error, storage_provider: mocked_storage_provider) }
  let(:expected_object_path) { subject.id }
  let(:expected_sub_path) { [subject.storage_container, expected_object_path].join('/')}
  let(:unexpected_exception) { StorageProviderException.new('Unexpected') }

  it_behaves_like 'an audited model'
  it_behaves_like 'a job_transactionable model'

  describe 'associations' do
    it {
      is_expected.to belong_to(:project)
    }
    it { is_expected.to belong_to(:storage_provider) }
    it { is_expected.not_to have_many(:chunks) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:fingerprints) }
  end

  it { is_expected.to accept_nested_attributes_for(:fingerprints) }

  describe 'validations' do
    it { is_expected.to validate_presence_of :project_id }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :size }
    it {
      is_expected.to validate_numericality_of(:size)
      .is_less_than(subject.max_size_bytes)
      .with_message("File size is currently not supported - maximum size is #{subject.max_size_bytes}")
    }
    it { is_expected.to validate_presence_of :storage_provider_id }
    it { is_expected.to validate_presence_of :creator_id }

    it { is_expected.not_to validate_presence_of :fingerprint_value }
    it { is_expected.not_to validate_presence_of :fingerprint_algorithm }

    it { is_expected.to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    it { is_expected.not_to validate_presence_of :fingerprints }
    it { is_expected.not_to validate_presence_of :multipart_upload_id }

    context 'when completed_at is set' do
      before { subject.completed_at = Faker::Time.forward(1) }
      it { is_expected.to validate_presence_of :fingerprints }
    end

    context 'when completed_at is nil' do
      let(:fingerprint) { FactoryBot.create(:fingerprint, upload: completed_upload) }
      it { is_expected.not_to be_completed_at }
      it { is_expected.not_to allow_value([fingerprint]).for(:fingerprints) }
    end

    context 'completed upload' do
      subject { completed_upload }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end

    context 'upload with error' do
      subject { upload_with_error }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end

    it 'expects storage_container to be immutable' do
      is_expected.to be_persisted
      is_expected.to allow_value(subject.project_id).for(:storage_container)
      is_expected.to allow_value(subject.storage_container).for(:storage_container)
      is_expected.not_to allow_value('a-different-string').for(:storage_container)
        .with_message("Cannot change storage_container.")
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_storage_container).before(:create) }
  end

  describe 'instance methods' do
    it { should delegate_method(:url_root).to(:storage_provider) }

    it 'should have a http_verb method' do
      should respond_to :http_verb
      expect(subject.http_verb).to eq 'GET'
    end

    it 'should have a sub_path method' do
      should respond_to :sub_path
      expect(subject.sub_path).to eq expected_sub_path
    end

    it 'should have an object_path method' do
      should respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end

    describe '#temporary_url' do
      it { is_expected.to respond_to :temporary_url }

      context 'when has_integrity_exception? true' do
        it {
          expect(subject).to receive(:has_integrity_exception?).and_return(true)
          expect {
            subject.temporary_url
          }.to raise_error(IntegrityException)
        }
      end

      context 'when not consistent' do
        before do
          expect(subject.update(is_consistent: false)).to be_truthy
        end
        it {
          expect(subject.is_consistent?).to be_falsey
          expect {
            subject.temporary_url
          }.to raise_error(ConsistencyException)
        }
      end

      context 'consistent and no integrity exceptions' do
        let(:expected_url) { Faker::Internet.url }
        before do
          expect(mocked_storage_provider).to receive(:download_url)
            .with(subject, expected_filename)
            .and_return(expected_url)
        end

        context 'when filename is provided' do
          let(:expected_filename) { 'different-file-name.txt' }
          it { expect(subject.temporary_url(expected_filename)).to eq(expected_url) }
        end

        context 'without filename' do
          let(:expected_filename) { nil }
          it { expect(subject.temporary_url).to eq(expected_url) }
        end
      end
    end

    it 'should have a completed_at attribute' do
      is_expected.to respond_to 'completed_at'
      is_expected.to respond_to 'completed_at='
    end
  end

  # Instance methods implemented in subclasses
  it { is_expected.not_to respond_to :manifest }
  it { is_expected.not_to respond_to :purge_storage }
  it { is_expected.not_to respond_to :initialize_storage }
  it { is_expected.not_to respond_to :ready_for_chunks? }
  it { is_expected.not_to respond_to :check_readiness! }
  it { is_expected.not_to respond_to :complete }

  describe '#has_integrity_exception?' do
    it { is_expected.to respond_to :has_integrity_exception? }

    context 'when upload is_consistent and has an error' do
      it {
        exactly_now = DateTime.now
        expect(
          subject.update({
            error_at: exactly_now,
            error_message: 'integrity exception',
            is_consistent: true
          })
        ).to be_truthy
        expect(subject.has_integrity_exception?).to be_truthy
      }
    end

    context 'when upload is_consistent and does not have an error' do
      it {
        exactly_now = DateTime.now
        expect(
          subject.update({
            is_consistent: true
          })
        ).to be_truthy
        expect(subject.has_integrity_exception?).to be_falsey
      }
    end
  end

  describe '#set_storage_container' do
    it { is_expected.to respond_to :set_storage_container }

    context 'upload creation' do
      subject { FactoryBot.build(:upload, storage_provider: mocked_storage_provider) }
      it {
        expect(subject.storage_container).to be_nil
        subject.save
        expect(subject.storage_container).to eq(subject.project_id)
      }
    end

    context 'upload update' do
      let(:original_storage_container) { subject.storage_container }
      let(:other_project) { completed_upload.project }

      it {
        expect(subject.storage_container).to eq(subject.project_id)
        expect(subject.storage_container).to eq(original_storage_container)
        subject.project = other_project
        subject.save
        expect(subject.storage_container).not_to eq(other_project.id)
        expect(subject.storage_container).to eq(original_storage_container)
      }
    end
  end

  describe '#max_size_bytes' do
    it { is_expected.to respond_to :max_size_bytes }
    it { expect(subject.max_size_bytes).to eq(mocked_storage_provider.max_chunked_upload_size) }
  end

  describe '#minimum_chunk_size' do
    it { is_expected.to respond_to :minimum_chunk_size }
    it {
      expect(subject.minimum_chunk_size).to eq(mocked_storage_provider.suggested_minimum_chunk_size(subject))
    }
  end

  it { is_expected.not_to respond_to :complete_and_validate_integrity }

  context 'when created with the Default StorageProvider' do
    let(:default_storage_provider) { FactoryBot.create(:swift_storage_provider, :default) }
    before(:example) do
      StorageProvider.delete_all
      expect(default_storage_provider).to be_persisted
      expect(StorageProvider.default).to eq default_storage_provider
    end
    context 'basic upload' do
      subject { FactoryBot.build(:upload, storage_provider: StorageProvider.default) }
      it { is_expected.to be_valid }
    end

    context 'completed upload' do
      subject { FactoryBot.build(:upload, :with_fingerprint, :completed, storage_provider: StorageProvider.default) }
      it { is_expected.to be_valid }
    end
  end
end
