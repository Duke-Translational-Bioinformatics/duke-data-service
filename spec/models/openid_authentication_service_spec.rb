require 'rails_helper'

RSpec.describe OpenidAuthenticationService, type: :model do
  subject { FactoryGirl.create(:openid_authentication_service, :openid_env) }
  let(:first_time_user) { FactoryGirl.attributes_for(:user) }
  let(:first_time_user_userinfo) {{
    sub: "#{first_time_user[:username]}@duke.edu",
    dukeNetID: first_time_user[:username],
    dukeUniqueID: "4444444",
    name: first_time_user[:display_name],
    given_name: first_time_user[:first_name],
    family_name: first_time_user[:last_name],
    email: first_time_user[:email],
    email_verified: false
  }}

  let(:first_time_user_access_token) {
    SecureRandom.hex
  }

  let(:existing_user) { FactoryGirl.create(:user) }
  let(:existing_user_auth) {
    FactoryGirl.create(:user_authentication_service,
    authentication_service: subject,
    uid: existing_user.username,
    user: existing_user)
  }
  let(:existing_user_access_token) {
    SecureRandom.hex
  }

  let(:existing_user_userinfo) {{
    sub: "#{existing_user.username}@duke.edu",
    dukeNetID: existing_user_auth.uid,
    dukeUniqueID: "4444444",
    name: existing_user.display_name,
    given_name: existing_user.first_name,
    family_name: existing_user.last_name,
    email: existing_user.email,
    email_verified: false
  }}

  let(:existing_first_authenticating_user) {
    FactoryGirl.create(:user)
  }
  let(:existing_first_authenticating_access_token) {
    SecureRandom.hex
  }
  let(:existing_first_authenticating_user_userinfo) {{
    sub: "#{existing_first_authenticating_user.username}@duke.edu",
    dukeNetID: existing_first_authenticating_user.username,
    dukeUniqueID: "4444444",
    name: existing_first_authenticating_user.display_name,
    given_name: existing_first_authenticating_user.first_name,
    family_name: existing_first_authenticating_user.last_name,
    email: existing_first_authenticating_user.email,
    email_verified: false
  }}

  let(:invalid_access_token) {
    SecureRandom.hex
  }

  include_context 'mocked openid request to', :subject
  it_behaves_like 'an authentication service'
end
