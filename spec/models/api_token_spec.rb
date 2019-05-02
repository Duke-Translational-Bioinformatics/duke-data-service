require 'rails_helper'

RSpec.describe ApiToken do
  let(:user) { FactoryBot.create(:user, :with_key) }

  it 'should require a User' do
    expect {
      ApiToken.new
    }.to raise_error('a User is required')
  end

  context 'with UserAuthenticationService Authenticated User' do
    let(:auth_service) { FactoryBot.create(:duke_authentication_service) }
    let(:user_authentication_service) { FactoryBot.create(:user_authentication_service,
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
      }.to raise_error('UserAuthenticationService or SoftwareAgent is required')
    end

    describe 'api_token and expires_on methods' do
      it 'should not require arguments' do
        expect(subject).to respond_to 'api_token'
        expect(subject).to respond_to 'expires_on'
        expect(subject).to respond_to 'time_to_live'
        expect{
          subject.api_token
          subject.expires_on
          subject.time_to_live
        }.not_to raise_error
      end

      it 'api_token should return JWT signed with the secret_key_base for the user and authentication_service expiring expires_on seconds into the future' do
        token = subject.api_token
        expires_on = subject.expires_on
        expect(expires_on).to eq(Time.now.to_i + 2.hours)
        decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
        expect(decoded_token).to be
        expect(decoded_token).to have_key('id')
        expect(decoded_token['id']).to eq(user.id)
        expect(decoded_token).to have_key('service_id')
        expect(decoded_token['service_id']).to eq(auth_service.service_id)
        expect(decoded_token).to have_key('exp')
        expect(decoded_token['exp']).to eq(expires_on.to_s)
      end
    end
  end

  context 'with SoftwareAgent authenticated User' do
    let (:software_agent) {
      FactoryBot.create(:software_agent, :with_key, creator: user)
    }

    subject {
      ApiToken.new(user: user, software_agent: software_agent)
    }

    it 'should require a User and SoftwareAgent' do
      expect {
        ApiToken.new(user: user)
      }.to raise_error('UserAuthenticationService or SoftwareAgent is required')
    end

    describe 'api_token and expires_on methods' do
      it 'should not require arguments' do
        expect(subject).to respond_to 'api_token'
        expect(subject).to respond_to 'expires_on'
        expect(subject).to respond_to 'time_to_live'
        expect{
          subject.api_token
          subject.expires_on
          subject.time_to_live
        }.not_to raise_error
      end

      it 'api_token should return JWT signed with the secret_key_base for the user and authentication_service expiring expires_on seconds into the future' do
        token = subject.api_token
        expires_on = subject.expires_on
        time_to_live = subject.time_to_live
        expected_time = Time.now.to_i + 2.hours
        expect(expires_on).to eq(Time.now.to_i + 2.hours)
        expect(time_to_live).to eq(2.hours.to_i)
        decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
        expect(decoded_token).to be
        expect(decoded_token).to have_key('id')
        expect(decoded_token['id']).to eq(user.id)
        expect(decoded_token).to have_key('software_agent_id')
        expect(decoded_token['software_agent_id']).to eq(software_agent.id)
        expect(decoded_token).to have_key('exp')
        expect(decoded_token['exp']).to eq(expires_on.to_s)
      end
    end
  end
end
