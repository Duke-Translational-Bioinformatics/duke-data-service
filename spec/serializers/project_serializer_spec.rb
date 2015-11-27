require 'rails_helper'

RSpec.describe ProjectSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:project) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('name')
      is_expected.to have_key('description')
      is_expected.to have_key('is_deleted')
      expect(subject['id']).to eq(resource.id)
      expect(subject['name']).to eq(resource.name)
      expect(subject['description']).to eq(resource.description)
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end
  end
end
