require 'rails_helper'

RSpec.describe UserAuthenticationService, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:auth_service) { FactoryBot.create(:duke_authentication_service) }
  subject { FactoryBot.create(:user_authentication_service,
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
end
