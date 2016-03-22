require 'rails_helper'

RSpec.describe StorageProviderSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:storage_provider) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('description')
      is_expected.to have_key('is_deprecated')
      is_expected.to have_key('chunk_hash_algorithm')
      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.display_name)
      expect(subject['description']).to eq(resource.description)
      expect(subject['is_deprecated']).to eq(resource.is_deprecated)
      expect(subject['chunk_hash_algorithm']).to eq(resource.chunk_hash_algorithm)
    end
  end
end
