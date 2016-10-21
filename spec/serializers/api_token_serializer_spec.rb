require 'rails_helper'

RSpec.describe ApiTokenSerializer, type: :serializer do
  let(:user) { FactoryGirl.create(:user) }
  let(:expected_attributes) {{
    'api_token' => resource.api_token,
    'expires_on' => resource.expires_on,
    'time_to_live' => resource.time_to_live
  }}

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
      it { is_expected.to include(expected_attributes) }
    end
  end
end
