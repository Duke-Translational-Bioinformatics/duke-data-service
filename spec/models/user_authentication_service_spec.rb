require 'rails_helper'

RSpec.describe UserAuthenticationService, type: :model do
  let(:user) { FactoryGirl.create(:user) }
  let(:auth_service) { FactoryGirl.create(:authentication_service) }
  subject { FactoryGirl.create(:user_authentication_service,
    user: user,
    authentication_service: auth_service
    )
  }
  it 'should belong_to user' do
    should belong_to :user
  end
  it 'should belong_to authentication_service' do
    should belong_to :authentication_service
  end

  it 'should require user_id' do
    should validate_presence_of :user_id
  end

  it 'should require authetication_service_id' do
    should validate_presence_of :authentication_service_id
  end

  it 'should require a uid that is unique for the authetication_service' do
    should validate_uniqueness_of(:uid)
            .scoped_to(:authentication_service_id)
            .with_message('your uid is not unique in the authentication service')
  end

  describe 'api_token' do
    let(:authentication_service) {
      a = FactoryGirl.create(:authentication_service)
      FactoryGirl.create(:user_authentication_service,
        authentication_service: a,
        user: subject)
      a
    }
    it 'should not require arguments' do
      expect(subject).to respond_to 'api_token'
      expect{
        subject.api_token
      }.not_to raise_error
    end

    it 'should return a JWT signed with the secret_key_base' do
      token = subject.api_token
      decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
      expect(decoded_token).to be
      expect(decoded_token).to have_key('id')
      expect(decoded_token['id']).to eq(subject.user_id)
      expect(decoded_token).to have_key('service_id')
      expect(decoded_token['service_id']).to eq(subject.authentication_service.service_id)
      expect(decoded_token).to have_key('exp')
      expect(decoded_token['exp']).to eq(Time.now.to_i + 2.hours.to_i)
    end
  end
end
