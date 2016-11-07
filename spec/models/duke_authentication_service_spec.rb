require 'rails_helper'

RSpec.describe DukeAuthenticationService, type: :model do
  subject { FactoryGirl.create(:duke_authentication_service) }
  it_behaves_like 'an authentication service'
end
