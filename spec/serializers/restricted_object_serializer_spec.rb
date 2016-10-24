require 'rails_helper'

RSpec.describe RestrictedObjectSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:folder) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('kind')
      is_expected.to have_key('id')
      is_expected.to have_key('is_deleted')

      expect(subject['id']).to eq(resource.id)
      expect(subject['kind']).to eq(resource.kind)
      expect(subject['is_deleted']).to eq(resource.is_deleted?)
    end
  end
end
