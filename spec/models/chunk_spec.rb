require 'rails_helper'

RSpec.describe Chunk, type: :model do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:upload) { FactoryBot.create(:upload, :skip_validation, storage_provider: mocked_storage_provider) }
  subject { FactoryBot.create(:chunk, :skip_validation, upload: upload) }
  include_context 'mock Chunk StorageProvider'

  let(:expected_object_path) { [subject.upload_id, subject.number].join('/')}
  let(:is_logically_deleted) { false }
  it_behaves_like 'an audited model'

  before do
    expect(upload).to be_persisted
    expect(subject).to be_persisted
  end

  describe 'associations' do
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to have_one(:storage_provider).through(:upload) }
    it { is_expected.to have_one(:project).through(:upload) }
    it { is_expected.to have_many(:project_permissions).through(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload_id) }
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_presence_of(:size) }
    it {
      is_expected.to validate_numericality_of(:size)
        .is_less_than(subject.chunk_max_size_bytes)
    }
    it { is_expected.to validate_presence_of(:fingerprint_value) }
    it { is_expected.to validate_presence_of(:fingerprint_algorithm) }
    it {
      # this validation creates a new chunk, which needs to use the
      # mocked_storage_provider for validation
      allow_any_instance_of(Chunk).to receive(:storage_provider)
        .and_return(mocked_storage_provider)
      is_expected.to validate_uniqueness_of(:number).scoped_to(:upload_id).case_insensitive
    }

    describe 'upload_chunk_maximum' do
      context 'storage_provider.chunk_max_exceeded? false' do
        it {
          is_expected.to be_valid
        }
      end

      context 'storage_provider.chunk_max_exceeded? true' do
        let(:expected_chunk_max_exceeded) { true }
        let(:expected_validation_message) { "maximum upload chunks exceeded." }

        it {
          is_expected.not_to be_valid
          expect(subject.errors.messages[:base]).to include expected_validation_message
        }
      end
    end
  end

  describe 'instance methods' do
    it 'should delegate #project_id and #storage_container to upload' do
      is_expected.to delegate_method(:project_id).to(:upload)
      expect(subject.project_id).to eq(subject.upload.project_id)
      is_expected.to delegate_method(:storage_container).to(:upload)
      expect(subject.storage_container).to eq(subject.upload.storage_container)
    end

    it { is_expected.to delegate_method(:chunk_max_size_bytes).to(:storage_provider) }
    it { is_expected.to delegate_method(:minimum_chunk_size).to(:upload) }

    it 'is_expected.to have a http_verb method' do
      is_expected.to respond_to :http_verb
      expect(subject.http_verb).to eq 'PUT'
    end

    it 'is_expected.to have a host method' do
      expect(mocked_storage_provider).to receive(:endpoint)
        .and_return(expected_endpoint)
      is_expected.to respond_to :host
      expect(subject.host).to eq expected_endpoint
    end

    it 'is_expected.to have a http_headers method' do
      is_expected.to respond_to :http_headers
      expect(subject.http_headers).to eq []
    end

    it 'is_expected.to have an object_path method' do
      is_expected.to respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end
  end

  describe '#url' do
    let(:expected_url) { Faker::Internet.url }

    it { is_expected.to respond_to :url }

    it {
      expect(mocked_storage_provider).to receive(:chunk_upload_url)
        .and_return(expected_url)

      expect(subject.url).to eq expected_url
    }
  end

  describe '#purge_storage' do
    let(:chunk_data) { 'some random chunk' }
    subject {
      FactoryBot.create(:chunk, :skip_validation, upload: upload, size: chunk_data.length, number: 1)
    }

    it { is_expected.to respond_to :purge_storage }

    context 'StorageProviderException' do
      let(:unexpected_exception) { StorageProviderException.new('Unexpected') }

      it {
        expect(mocked_storage_provider).to receive(:purge)
          .with(subject)
          .and_raise(unexpected_exception)
        expect {
          subject.purge_storage
        }.to raise_error(unexpected_exception)
      }
    end

    context 'success' do
      it {
        expect(mocked_storage_provider).to receive(:purge)
          .with(subject)

        expect {
          subject.purge_storage
        }.not_to raise_error
      }
    end
  end

  context  'when created with the default StorageProvider' do
    it 'should be valid' do
      StorageProvider.delete_all
      default_storage_provider = FactoryBot.create(:swift_storage_provider, :default)
      expect(StorageProvider.default).not_to be_nil
      upload = FactoryBot.create(:upload, storage_provider: StorageProvider.default)
      chunk = FactoryBot.create(:chunk, upload: upload)
      expect(chunk).to be_valid
    end
  end
end
