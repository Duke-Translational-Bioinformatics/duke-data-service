require 'rails_helper'

RSpec.describe UploadSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:upload, :with_chunks) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'content_type' => resource.content_type,
    'size' => resource.size,
    'etag' => resource.etag,
    'is_consistent' => resource.is_consistent,
    'status' => {
      'initiated_on' => resource.created_at.as_json,
      'completed_on' => resource.completed_at.as_json,
      'error_on' => resource.error_at.as_json,
      'error_message' => resource.error_message
    }
  }}

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer
  it_behaves_like 'a has_many association with', :chunks, ChunkPreviewSerializer
  it_behaves_like 'a has_many association with', :fingerprints, FingerprintSerializer, root: :hashes

  it_behaves_like 'a json serializer' do
    it { is_expected.not_to have_key('hash') }
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end

  context 'with completed upload' do
    let(:resource) { FactoryGirl.create(:upload, :with_chunks, :completed, :with_fingerprint) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'when upload has error' do
    let(:resource) { FactoryGirl.create(:upload, :with_chunks, :with_error) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end
end
