require 'rails_helper'

RSpec.describe ApiTokenSerializer, type: :serializer do
  let(:user) { FactoryGirl.create(:user) }

  context 'with UserAuthenticationService Authenticated User' do
    let(:auth_service) { FactoryGirl.create(:authentication_service) }
    let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service,
      user: user,
      authentication_service: auth_service
      )
    }
    let(:resource) {
      ApiToken.new(user: user, user_authentication_service: user_authentication_service)
    }
    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('api_token')
        is_expected.to have_key('expires_on')
        is_expected.to have_key('time_to_live')
        expect(subject['api_token']).to be
        expect(subject['expires_on']).to be
        expect(subject['time_to_live']).to be
      end
    end
  end
end
