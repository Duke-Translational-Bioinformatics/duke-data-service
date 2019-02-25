require 'rails_helper'

RSpec.describe ChunkSerializer, type: :serializer do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:chunked_upload) { FactoryBot.create(:chunked_upload, :with_chunks, storage_provider: mocked_storage_provider) }
  let(:resource) { FactoryBot.create(:chunk, chunked_upload: chunked_upload) }
  include_context 'mock Chunk StorageProvider', on: [:resource]

  let(:expected_attributes) {{
    'http_verb' => resource.http_verb,
    'host' => resource.host,
    'url' => resource.url,
    'http_headers' => resource.http_headers
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
