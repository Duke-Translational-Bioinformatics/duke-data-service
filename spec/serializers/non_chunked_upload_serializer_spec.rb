require 'rails_helper'

RSpec.describe NonChunkedUploadSerializer, type: :serializer do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:resource) { FactoryBot.create(:non_chunked_upload, storage_provider: mocked_storage_provider) }
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
      'is_consistent' => resource.is_consistent.as_json,
      'purged_on' => resource.purged_on.as_json,
      'error_on' => resource.error_at.as_json,
      'error_message' => resource.error_message
    },
    'signed_url' => {
      'http_verb' => 'PUT',
      'host' => mocked_storage_provider.url_root,
      'url' => resource.single_file_upload_url,
      'http_headers' => []
    }
  }}
  let(:signed_url) { '/' + Faker::Internet.user_name }
  before(:example) { allow(resource).to receive(:single_file_upload_url).and_return(signed_url) }

  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer
  it_behaves_like 'a has_many association with', :fingerprints, FingerprintSerializer, root: :hashes

  it_behaves_like 'a json serializer' do
    it { is_expected.not_to have_key('hash') }
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end

  context 'with completed non_chunked_upload' do
    let(:resource) { FactoryBot.create(:non_chunked_upload, :completed, :with_fingerprint, storage_provider: mocked_storage_provider) }
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
        'is_consistent' => resource.is_consistent.as_json,
        'purged_on' => resource.purged_on.as_json,
        'error_on' => resource.error_at.as_json,
        'error_message' => resource.error_message
      }
    }}
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
      it { is_expected.not_to have_key('signed_url') }
    end
  end

  context 'with inconsistent non_chunked_upload' do
    let(:resource) { FactoryBot.create(:non_chunked_upload, :inconsistent, storage_provider: mocked_storage_provider) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'when non_chunked_upload has error' do
    let(:resource) { FactoryBot.create(:non_chunked_upload, :with_error, storage_provider: mocked_storage_provider) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end

  context 'when non_chunked_upload is purged' do
    let(:resource) { FactoryBot.create(:non_chunked_upload, storage_provider: mocked_storage_provider, purged_on: DateTime.now) }
    it_behaves_like 'a json serializer' do
      it { is_expected.to include(expected_attributes) }
    end
  end
end
