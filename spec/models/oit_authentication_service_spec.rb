require 'rails_helper'

RSpec.describe OitAuthenticationService, type: :model do
  subject { FactoryGirl.create(:oit_authentication_service) }
  it_behaves_like 'an authentication service'
end
