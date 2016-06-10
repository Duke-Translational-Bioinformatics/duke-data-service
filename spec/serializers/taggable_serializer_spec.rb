require 'rails_helper'

RSpec.describe TaggableSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:data_file) }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('kind')
      is_expected.to have_key('id')
      expect(subject['kind']).to eq(resource.kind)
      expect(subject['id']).to eq(resource.id)
    end
  end
end
