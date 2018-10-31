require 'rails_helper'

RSpec.describe ChunkSerializer, type: :serializer do
  let(:upload) { FactoryBot.create(:upload, :skip_validation) }
  let(:resource) { FactoryBot.create(:chunk, :skip_validation, upload: upload) }
  let(:expected_endpoint) { Faker::Internet.url }
  let(:expected_chunk_upload_url) { "#{expected_endpoint}/#{resource.sub_path}" }

  include_context 'with mocked StorageProvider', on: [:resource, :upload]

  let(:expected_attributes) {{
    'http_verb' => resource.http_verb,
    'host' => resource.host,
    'url' => resource.url,
    'http_headers' => resource.http_headers
  }}

  before do
    allow(mocked_storage_provider).to receive(:endpoint)
      .and_return(expected_endpoint)
    allow(mocked_storage_provider).to receive(:chunk_upload_url)
      .and_return(expected_chunk_upload_url)
  end

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
