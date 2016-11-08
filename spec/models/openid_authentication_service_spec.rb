require 'rails_helper'

RSpec.describe OpenidAuthenticationService, type: :model do
  subject { FactoryGirl.create(:openid_authentication_service, :openid_env) }
  let(:first_time_user) { FactoryGirl.attributes_for(:user) }
  let(:first_time_user_userinfo) {{
    sub: "#{first_time_user[:username]}@duke.edu",
    name: first_time_user[:display_name],
    given_name: first_time_user[:first_name],
    family_name: first_time_user[:last_name],
    email: first_time_user[:email],
    email_verified: false
  }}
  let(:first_time_user_introspect) {{
    active: true,
    scope: "openid email profile",
    expires_at: "2016-11-08T12:40:24-0500",
    exp: 1478626824,
    sub: "#{first_time_user[:username]}@duke.edu",
    dukeNetID: "#{first_time_user[:username]}",
    dukeUniqueID: "4444444",
    user_id: "#{first_time_user[:username]}@duke.edu",
    client_id: "dds_dev",
    token_type: "Bearer",
    azp: "dds_dev"
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
    name: existing_user.display_name,
    given_name: existing_user.first_name,
    family_name: existing_user.last_name,
    email: existing_user.email,
    email_verified: false
  }}
  let(:existing_user_introspect) {{
    active: true,
    scope: "openid email profile",
    expires_at: "2016-11-08T12:40:24-0500",
    exp: 1478626824,
    sub: "#{existing_user.username}@duke.edu",
    dukeNetID: "#{existing_user_auth.uid}",
    dukeUniqueID: "4444444",
    user_id: "#{existing_user.username}@duke.edu",
    client_id: "dds_dev",
    token_type: "Bearer",
    azp: "dds_dev"
  }}

  let(:existing_first_authenticating_user) {
    FactoryGirl.create(:user)
  }
  let(:existing_first_authenticating_access_token) {
    SecureRandom.hex
  }
  let(:existing_first_authenticating_user_userinfo) {{
    sub: "#{existing_first_authenticating_user.username}@duke.edu",
    name: existing_first_authenticating_user.display_name,
    given_name: existing_first_authenticating_user.first_name,
    family_name: existing_first_authenticating_user.last_name,
    email: existing_first_authenticating_user.email,
    email_verified: false
  }}
  let(:existing_first_authenticating_user_introspect) {{
    active: true,
    scope: "openid email profile",
    expires_at: "2016-11-08T12:40:24-0500",
    exp: 1478626824,
    sub: "#{existing_first_authenticating_user.username}@duke.edu",
    dukeNetID: "#{existing_first_authenticating_user.username}",
    dukeUniqueID: "4444444",
    user_id: "#{existing_first_authenticating_user.username}@duke.edu",
    client_id: "dds_dev",
    token_type: "Bearer",
    azp: "dds_dev"
  }}

  let(:invalid_access_token) {
    SecureRandom.hex
  }

  before do
    WebMock.reset!
    stub_request(:post, "#{subject.base_uri}/userinfo").
      with(:body => "access_token=#{first_time_user_access_token}").
      to_return(:status => 200, :body => first_time_user_userinfo.to_json)
    stub_request(:post, "#{subject.base_uri}/introspect").
      with(:body => "token=#{first_time_user_access_token}").
      to_return(:status => 200, :body => first_time_user_introspect.to_json)

    stub_request(:post, "#{subject.base_uri}/userinfo").
      with(:body => "access_token=#{existing_user_access_token}").
      to_return(:status => 200, :body => existing_user_userinfo.to_json)
    stub_request(:post, "#{subject.base_uri}/introspect").
      with(:body => "token=#{existing_user_access_token}").
      to_return(:status => 200, :body => existing_user_introspect.to_json)

    stub_request(:post, "#{subject.base_uri}/userinfo").
      with(:body => "access_token=#{existing_first_authenticating_access_token}").
      to_return(:status => 200, :body => existing_first_authenticating_user_userinfo.to_json)
    stub_request(:post, "#{subject.base_uri}/introspect").
      with(:body => "token=#{existing_first_authenticating_access_token}").
      to_return(:status => 200, :body => existing_first_authenticating_user_introspect.to_json)

    stub_request(:post, "#{subject.base_uri}/userinfo").
      with(:body => "access_token=#{invalid_access_token}").
      to_return(:status => 401, :body => {error: "invalid_token", error_description: "Invalid access token: #{invalid_access_token}"}.to_json)
  end

  it_behaves_like 'an authentication service'
end
