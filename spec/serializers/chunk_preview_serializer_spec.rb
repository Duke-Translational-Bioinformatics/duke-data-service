require 'rails_helper'

RSpec.describe ChunkPreviewSerializer, type: :serializer do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:upload) { FactoryBot.create(:upload, :with_chunks, storage_provider: mocked_storage_provider) }
  let(:resource) { upload.chunks.first }

  let(:expected_attributes) {{
    'number' => resource.number,
    'size' => resource.size,
    'hash' => { 'value' => resource.fingerprint_value,
                'algorithm' => resource.fingerprint_algorithm }
  }}

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
  end
end
