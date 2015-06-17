require 'rails_helper'
require 'shoulda-matchers'
require 'jwt'

RSpec.describe User, type: :model do
  subject {FactoryGirl.create(:user)}

  it 'should have_many user_authentication_services' do
    should have_many :user_authentication_services
  end

  describe 'api_token' do
    it 'should return a JWT signed with the secret_key_base' do
      expect(subject).to respond_to 'api_token'
      token = subject.api_token
      decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
      expect(decoded_token).to be
      expect(decoded_token).to have_key('id')
      expect(decoded_token['id']).to eq(subject.id)
      expect(decoded_token).to have_key('uuid')
      expect(decoded_token['uuid']).to eq(subject.uuid)
      expect(decoded_token).to have_key('exp')
      expect(decoded_token['exp']).to eq(Time.now.to_i + 2.hours.to_i)
    end
  end
end
