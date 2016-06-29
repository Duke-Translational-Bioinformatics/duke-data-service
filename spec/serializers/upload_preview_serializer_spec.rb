require 'rails_helper'

RSpec.describe UploadPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:upload, :with_chunks, :completed, :with_error) }

  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer
  it_behaves_like 'a has_many association with', :fingerprints, FingerprintSerializer, root: :hashes

  it_behaves_like 'a json serializer' do
    it { is_expected.not_to have_key('hash') }
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('size')
      expect(subject["id"]).to eq(resource.id)
      expect(subject["size"]).to eq(resource.size)
    end
  end
end
