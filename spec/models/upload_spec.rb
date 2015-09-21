require 'rails_helper'

RSpec.describe Upload, type: :model do
  subject { FactoryGirl.create(:upload, :with_chunks) }
  let(:expected_sub_path) { [subject.project_id, subject.id].join('/')}

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

    let(:complete) { subject.complete }
    it 'should have a complete method' do
      is_expected.to respond_to 'complete'
      expect { complete }.not_to raise_error
      expect(complete).to be_truthy
    end
  end

  describe 'serialization' do
    let(:expected_keys) {
      %w(
        id
        project
        name
        content_type
        size
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
        "name" => subject.storage_provider.name,
      })
      expect(parsed_json["status"]).to be_a Hash
      %w(initiated_on completed_on).each do |ekey|
        expect(parsed_json["status"]).to have_key ekey
      end
      expect(DateTime.parse(parsed_json["status"]["initiated_on"]).to_i).to eq(subject.created_at.to_i)
      if subject.completed_at
        expect(DateTime.parse(parsed_json["status"]["completed_on"]).to_i).to eq(subject.completed_at.to_i)
      else
        expect(parsed_json["status"]["completed_on"]).to eq(subject.completed_at)
      end
    end
  end
end
