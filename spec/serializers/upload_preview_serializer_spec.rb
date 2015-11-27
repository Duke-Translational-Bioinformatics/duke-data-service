require 'rails_helper'

RSpec.describe UploadPreviewSerializer, type: :serializer do
  it 'should have one storage_provider preview' do
    expect(described_class._associations).to have_key(:storage_provider)
    expect(described_class._associations[:storage_provider]).to be_a(ActiveModel::Serializer::Association::HasOne)
    expect(described_class._associations[:storage_provider].serializer_from_options).to eq(StorageProviderPreviewSerializer)
  end

  describe 'serializer#to_json' do
    let(:resource) { FactoryGirl.create(:upload, :with_chunks, :completed, :with_error) }
    let(:serializer) { UploadPreviewSerializer.new resource }
    subject { JSON.parse(serializer.to_json) }

    it 'should serialize to json' do
      expect{subject}.to_not raise_error
    end

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
end
