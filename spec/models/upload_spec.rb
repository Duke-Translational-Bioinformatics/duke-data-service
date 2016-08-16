require 'rails_helper'

RSpec.describe Upload, type: :model do
  subject { FactoryGirl.create(:upload, :with_chunks) }
  let(:completed_upload) { FactoryGirl.create(:upload, :with_chunks, :with_fingerprint, :completed) }
  let(:upload_with_error) { FactoryGirl.create(:upload, :with_chunks, :with_error) }
  let(:expected_object_path) { subject.id }
  let(:expected_sub_path) { [subject.project_id, expected_object_path].join('/')}

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:storage_provider) }
    it { is_expected.to have_many(:chunks) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:fingerprints) }
  end

  it { is_expected.to accept_nested_attributes_for(:fingerprints) }

  describe 'validations' do
    it { is_expected.to validate_presence_of :project_id }
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_presence_of :size }
    it { is_expected.to validate_presence_of :storage_provider_id }
    it { is_expected.to validate_presence_of :creator_id }

    it { is_expected.not_to validate_presence_of :fingerprint_value }
    it { is_expected.not_to validate_presence_of :fingerprint_algorithm }

    it { is_expected.to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    it { is_expected.not_to validate_presence_of :fingerprints }

    context 'when completed_at is set' do
      before { subject.completed_at = Faker::Time.forward(1) }
      it { is_expected.to validate_presence_of :fingerprints }
    end

    context 'completed upload' do
      subject { completed_upload }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end

    context 'upload with error' do
      subject { upload_with_error }
      it { is_expected.not_to allow_value(Faker::Time.forward(1)).for(:completed_at) }
    end
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
      it { expect(subject.temporary_url).to be_a String }
      it { expect(subject.temporary_url).to include subject.name }

      context 'when filename is provided' do
        let(:filename) { 'different-file-name.txt' }
        it { expect(subject.temporary_url(filename)).to include filename }
      end
    end

    it 'should have a completed_at attribute' do
      is_expected.to respond_to 'completed_at'
      is_expected.to respond_to 'completed_at='
    end

    it 'should have a manifest method' do
      is_expected.to respond_to 'manifest'
      expect(subject.manifest).to be_a Array
      expect(subject.chunks).not_to be_empty
      expect(subject.manifest.count).to eq(subject.chunks.count)
      subject.chunks.reorder(:number).each do |chunk|
        chunk_manifest = {
          path: chunk.sub_path,
          etag: chunk.fingerprint_value,
          size_bytes: chunk.size
        }
        expect(subject.manifest[chunk.number - 1]).to eq chunk_manifest
      end
    end
  end

  describe 'swift methods', :vcr do
    subject { FactoryGirl.create(:upload, :swift, :with_chunks, :with_fingerprint) }

    describe '.initialize_storage_provider' do
      it { is_expected.to respond_to 'initialize_storage_provider' }

      it 'should create the upload container in the storage provider' do
        expect(subject.storage_provider.get_container_meta(subject.project_id)).to be_nil
        subject.initialize_storage_provider
        expect(subject.storage_provider.get_container_meta(subject.project_id)).to be
      end
    end

    describe 'complete' do
      it 'should be implemented' do
        is_expected.to respond_to 'complete'
      end

      describe 'calls' do
        before do
          actual_size = 0
          subject.storage_provider.put_container(subject.project_id)
          subject.chunks.each do |chunk|
            object = [subject.id, chunk.number].join('/')
            body = 'this is a chunk'
            subject.storage_provider.put_object(
              subject.project_id,
              object,
              body
            )
            chunk.update_attributes({
              fingerprint_value: Digest::MD5.hexdigest(body),
              size: body.length
            })
            actual_size = body.length + actual_size
          end
          subject.update_attribute(:size, actual_size)
        end

        after do
          subject.chunks.each do |chunk|
            object = [subject.id, chunk.number].join('/')
            subject.storage_provider.delete_object(subject.project_id, object)
          end
        end

        describe 'with valid reported size and chunk hashes' do
          it 'should update completed_at, leave error_at and error_message null and return true' do
            expect {
              is_complete = subject.complete
              expect(is_complete).to be_truthy
            }.not_to raise_error
            subject.reload
            expect(subject.completed_at).not_to be_nil
            expect(subject.error_at).to be_nil
            expect(subject.error_message).to be_nil
          end
        end #with valid

        describe 'with reported size not equal to swift computed size' do
          it 'should update completed_at, error_at and error_message and raise an IntegrityException' do
            subject.update_attribute(:size, subject.size - 1)
            expect { subject.complete }.to raise_error(IntegrityException)
            subject.reload
            expect(subject.completed_at).to be_nil
            expect(subject.error_at).not_to be_nil
            expect(subject.error_message).not_to be_nil
          end
        end #with reported size

        describe 'with reported chunk hash not equal to swift computed chunk etag' do
          it 'should update completed_at, error_at and error_message and raise an IntegrityException' do
            bad_chunk = subject.chunks.first
            bad_chunk.update_attribute(:fingerprint_value, "NOTTHECOMPUTEDHASH")
            expect {
              subject.complete
            }.to raise_error(IntegrityException)
            subject.reload
            expect(subject.completed_at).to be_nil
            expect(subject.error_at).not_to be_nil
            expect(subject.error_message).not_to be_nil
          end
        end #with reported chunk

      end #calls
    end #complete
  end #swift methods
end
