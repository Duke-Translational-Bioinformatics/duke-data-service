require 'rails_helper'

RSpec.describe UploadPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:upload, :with_chunks, :completed, :with_error) }

  it_behaves_like 'a has_one association with', :storage_provider, StorageProviderPreviewSerializer

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('size')
      is_expected.to have_key('hash')
      expect(subject["id"]).to eq(resource.id)
      expect(subject["size"]).to eq(resource.size)
      expect(subject["hash"]).to eq({
        "value" => resource.fingerprint_value,
        "algorithm" => resource.fingerprint_algorithm
      })
    end
  end

  context 'upload without fingerprint' do
    let(:resource) { FactoryGirl.create(:upload, :without_fingerprint, :with_chunks, :completed, :with_error) }

    it_behaves_like 'a json serializer' do
      it { is_expected.to have_key "hash" }
      it { expect(subject["hash"]).to eq(nil) }
    end
  end
end
