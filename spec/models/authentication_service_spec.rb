require 'rails_helper'

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
end
