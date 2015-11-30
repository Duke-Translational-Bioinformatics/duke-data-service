require 'rails_helper'

RSpec.describe UploadSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:upload, :with_chunks, :completed, :with_error) }
  let(:expected_keys) {
    %w(
      id
      name
      content_type
      size
      etag
      hash
      chunks
      status
    )
  }

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      expected_keys.each do |ekey|
        is_expected.to have_key ekey
      end
      expect(subject["id"]).to eq(resource.id)
      expect(subject["name"]).to eq(resource.name)
      expect(subject["content_type"]).to eq(resource.content_type)
      expect(subject["size"]).to eq(resource.size)
      expect(subject["hash"]).to eq({
        "value" => resource.fingerprint_value,
        "algorithm" => resource.fingerprint_algorithm,
        "client_reported" => true,
        "confirmed" => false
      })
      expect(subject["chunks"]).to eq(
        resource.chunks.collect{ |chunk|
          {
            "number" => chunk.number,
            "size" => chunk.size,
            "hash" => { "value" => chunk.fingerprint_value, "algorithm" => chunk.fingerprint_algorithm }
          }
        }
      )
      expect(subject["status"]).to be_a Hash
      %w(initiated_on completed_on error_on error_message).each do |ekey|
        expect(subject["status"]).to have_key ekey
      end
      expect(DateTime.parse(subject["status"]["initiated_on"]).to_i).to eq(resource.created_at.to_i)
      expect(DateTime.parse(subject["status"]["completed_on"]).to_i).to eq(resource.completed_at.to_i)
      expect(DateTime.parse(subject["status"]["error_on"]).to_i).to eq(resource.error_at.to_i)
      expect(subject["status"]["error_message"]).to eq(resource.error_message)
    end
  end
end
