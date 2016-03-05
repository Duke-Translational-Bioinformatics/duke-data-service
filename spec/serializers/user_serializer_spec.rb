require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:resource) { user_authentication_service.user }
  let(:is_logically_deleted) { false }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      is_expected.to have_key('username')
      is_expected.to have_key('full_name')
      is_expected.to have_key('first_name')
      is_expected.to have_key('last_name')
      is_expected.to have_key('email')
      is_expected.to have_key('auth_provider')
      is_expected.to have_key('last_login_on')
      expect(subject['id']).to eq(resource.id)
      expect(subject['username']).to eq(resource.username)
      expect(subject['full_name']).to eq(resource.display_name)
      expect(subject['first_name']).to eq(resource.first_name)
      expect(subject['last_name']).to eq(resource.last_name)
      expect(subject['email']).to eq(resource.email)
      expect(subject['auth_provider']).to have_key('uid')
      expect(subject['auth_provider']).to have_key('source')
      expect(subject['auth_provider']['uid']).to eq(user_authentication_service.uid)
      expect(subject['auth_provider']['source']).to eq(user_authentication_service.authentication_service.name)
      expect(subject['last_login_on'].to_json).to eq(resource.last_login_at.to_json)
    end
    it_behaves_like 'a serializer with a serialized audit'
  end
end
