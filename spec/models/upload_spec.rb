require 'rails_helper'

RSpec.describe Upload, type: :model do
  subject { FactoryGirl.create(:upload, :with_chunks) }
  let(:expected_sub_path) { [subject.project_id, subject.id].join('/')}
  let(:is_logically_deleted) { false }

  it_behaves_like 'an audited model' do
    it_behaves_like 'with a serialized audit'
  end

  describe 'associations' do
    it 'should belong_to a project' do
      should belong_to :project
    end

    it 'should belong_to a storage_provider' do
      should belong_to :storage_provider
    end

    it 'should have_many chunks' do
      should have_many :chunks
    end

    it 'should have many project permissions' do
      should have_many(:project_permissions).through(:project)
    end
  end

  describe 'validations' do
    it 'should require attributes' do
      should validate_presence_of :project_id
      should validate_presence_of :name
      should validate_presence_of :size
      should validate_presence_of :fingerprint_value
      should validate_presence_of :fingerprint_algorithm
      should validate_presence_of :storage_provider_id
    end
  end

  describe 'instance methods' do
    it 'should have a sub_path method' do
      should respond_to :sub_path
      expect(subject.sub_path).to eq expected_sub_path
    end

    it 'should have a temporary_url method' do
      is_expected.to respond_to :temporary_url
      expect(subject.temporary_url).to be_a String
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
      subject.chunks.each do |chunk|
        chunk_manifest = {
          path: chunk.sub_path,
          etag: chunk.fingerprint_value,
          size_bytes: chunk.size
        }
        expect(subject.manifest).to include chunk_manifest
      end
    end
  end

  describe 'swift methods', :vcr => {:match_requests_on => [:method, :uri_ignoring_uuids]} do
    subject { FactoryGirl.create(:upload, :swift, :with_chunks) }

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
            expect(subject.completed_at).to be
            expect(subject.error_at).to be_nil
            expect(subject.error_message).to be_nil
          end
        end #with valid

        describe 'with reported size not equal to swift computed size' do
          it 'should update completed_at, error_at and error_message and raise an IntegrityException' do
            subject.update_attribute(:size, subject.size - 1)
            expect { subject.complete }.to raise_error(IntegrityException)
            subject.reload
            expect(subject.completed_at).to be
            expect(subject.error_at).to be
            expect(subject.error_message).to be
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
            expect(subject.completed_at).to be
            expect(subject.error_at).to be
            expect(subject.error_message).to be
          end
        end #with reported chunk

      end #calls
    end #complete
  end #swift methods

  describe 'serialization' do
    subject { FactoryGirl.create(:upload, :with_chunks, :completed, :with_error) }

    let(:expected_keys) {
      %w(
        id
        project
        name
        content_type
        size
        etag
        hash
        chunks
        storage_provider
        status
      )
    }
    it 'should serialize to json' do
      serializer = UploadSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expected_keys.each do |ekey|
        expect(parsed_json).to have_key ekey
      end
      expect(parsed_json["id"]).to eq(subject.id)
      expect(parsed_json["project"]).to eq({"id" => subject.project.id})
      expect(parsed_json["name"]).to eq(subject.name)
      expect(parsed_json["content_type"]).to eq(subject.content_type)
      expect(parsed_json["size"]).to eq(subject.size)
      expect(parsed_json["hash"]).to eq({
        "value" => subject.fingerprint_value,
        "algorithm" => subject.fingerprint_algorithm,
        "client_reported" => true,
        "confirmed" => false
      })
      expect(parsed_json["chunks"]).to eq(
        subject.chunks.collect{ |chunk|
          {
            "number" => chunk.number,
            "size" => chunk.size,
            "hash" => { "value" => chunk.fingerprint_value, "algorithm" => chunk.fingerprint_algorithm }
          }
        }
      )
      expect(parsed_json["storage_provider"]).to eq({
        "id" => subject.storage_provider.id,
        "description" => subject.storage_provider.description,
        "name" => subject.storage_provider.display_name,
      })
      expect(parsed_json["status"]).to be_a Hash
      %w(initiated_on completed_on error_on error_message).each do |ekey|
        expect(parsed_json["status"]).to have_key ekey
      end
      expect(DateTime.parse(parsed_json["status"]["initiated_on"]).to_i).to eq(subject.created_at.to_i)
      expect(DateTime.parse(parsed_json["status"]["completed_on"]).to_i).to eq(subject.completed_at.to_i)
      expect(DateTime.parse(parsed_json["status"]["error_on"]).to_i).to eq(subject.error_at.to_i)
      expect(parsed_json["status"]["error_message"]).to eq(subject.error_message)
    end
  end
end
