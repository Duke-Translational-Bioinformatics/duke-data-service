require 'rails_helper'

RSpec.describe UserApiSecretSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:user_api_secret, :populated ) }
  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('key')
      is_expected.to have_key('created_at')
      expect(subject['key']).to eq(resource.key)
    end
  end
end
