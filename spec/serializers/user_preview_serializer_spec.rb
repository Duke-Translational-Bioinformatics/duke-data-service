require 'rails_helper'

RSpec.describe UserPreviewSerializer, type: :serializer do
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:resource) { user_authentication_service.user }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('username')
      is_expected.to have_key('full_name')
      expect(subject['id']).to eq(resource.id)
      expect(subject['username']).to eq(resource.username)
      expect(subject['full_name']).to eq(resource.display_name)
    end
  end
end
