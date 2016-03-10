require 'rails_helper'

RSpec.describe ApiKeySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:api_key) }
  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('key')
      is_expected.to have_key('created_on')
      expect(subject['key']).to eq(resource.key)
    end
  end
end
