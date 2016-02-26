require 'rails_helper'

RSpec.describe ApiToken do
  let(:user) { FactoryGirl.create(:user) }

  it 'should require a User' do
    expect {
      ApiToken.new
    }.to raise_error(RuntimeError)
  end

  context 'with UserAuthenticationService Authenticated User' do
    let(:auth_service) { FactoryGirl.create(:authentication_service) }
    let(:user_authentication_service) { FactoryGirl.create(:user_authentication_service,
      user: user,
      authentication_service: auth_service
      )
    }
    subject {
      ApiToken.new(user: user, user_authentication_service: user_authentication_service)
    }

    it 'should require a User and UserAuthenticationService' do
      expect {
        ApiToken.new(user: user)
      }.to raise_error(RuntimeError)
    end

    describe 'api_token method' do
      it 'should not require arguments' do
        expect(subject).to respond_to 'api_token'
        expect{
          subject.api_token
        }.not_to raise_error
      end

      it 'should return JWT signed with the secret_key_base for the user and authentication_service' do
        token = subject.api_token
        decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
        expect(decoded_token).to be
        expect(decoded_token).to have_key('id')
        expect(decoded_token['id']).to eq(user.id)
        expect(decoded_token).to have_key('service_id')
        expect(decoded_token['service_id']).to eq(auth_service.service_id)
        expect(decoded_token).to have_key('exp')
        expect(decoded_token['exp']).to eq(Time.now.to_i + 2.hours.to_i)
      end
    end
  end
end
