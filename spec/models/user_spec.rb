require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe User, type: :model do
  subject {FactoryGirl.create(:user)}

  it 'should have_many user_authentication_services' do
    should have_many :user_authentication_services
  end
end
