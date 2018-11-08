require 'rails_helper'

RSpec.describe UploadSerializer, type: :serializer do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:resource) { FactoryBot.create(:upload, :with_chunks, storage_provider: mocked_storage_provider) }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'content_type' => resource.content_type,
    'storage_container' => resource.storage_container,
    'size' => resource.size,
    'etag' => resource.etag,
    'status' => {
      'initiated_on' => resource.created_at.as_json,
      'completed_on' => resource.completed_at.as_json,
      'purged_on' => resource.purged_on.as_json,
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
    let(:resource) { FactoryBot.create(:upload, :with_chunks, :completed, :with_fingerprint, storage_provider: mocked_storage_provider) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'when upload has error' do
    let(:resource) { FactoryBot.create(:upload, :with_chunks, :with_error, storage_provider: mocked_storage_provider) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'when upload is purged' do
    let(:resource) { FactoryBot.create(:upload, :with_chunks, storage_provider: mocked_storage_provider, purged_on: DateTime.now) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end
end
