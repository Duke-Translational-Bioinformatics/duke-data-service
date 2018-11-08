require 'rails_helper'

RSpec.describe UploadPreviewSerializer, type: :serializer do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  let(:resource) { FactoryBot.create(:upload, :with_chunks, storage_provider: mocked_storage_provider) }

  let(:expected_attributes) {{
    'id' => resource.id,
    'size' => resource.size
  }}

  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer
  it_behaves_like 'a has_many association with', :fingerprints, FingerprintSerializer, root: :hashes

  it_behaves_like 'a json serializer' do
    it { is_expected.not_to have_key('hash') }
    it { is_expected.to include(expected_attributes) }
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
end
