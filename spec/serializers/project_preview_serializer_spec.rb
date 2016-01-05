require 'rails_helper'

RSpec.describe ProjectPreviewSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:project) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      expect(subject['id']).to eq(resource.id)
    end
  end
end
