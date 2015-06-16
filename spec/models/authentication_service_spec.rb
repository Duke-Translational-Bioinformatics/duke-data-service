require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe AuthenticationService, type: :model do
  subject { FactoryGirl.create(:authentication_service) }
  describe 'associations' do
    it 'should have many user_authentication_services' do
      should have_many(:user_authentication_services)
    end
  end

  it 'should require a unique uuid' do
    should validate_uniqueness_of :uuid
  end

  it 'should require a name' do
    should validate_presence_of :name
  end

  it 'should require a base_uri' do
    should validate_presence_of :base_uri
  end

  describe 'token_info' do
    let(:token) {SecureRandom.hex}
    it 'should require an access_token' do
      should respond_to 'token_info'
      expect{
        subject.token_info()
      }.to raise_error(ArgumentError)
      expect{
        subject.token_info(token)
      }.not_to raise_error
    end

    it 'should call base_uri/api/v1/user/token_info with the supplied token and return the response' do
      pending 'To Be Implemented'
      expect(subject.token_info(token)).to be
    end
  end
end
