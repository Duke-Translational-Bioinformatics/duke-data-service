require 'rails_helper'

RSpec.describe DukeAuthenticationService, type: :model do
  subject { FactoryGirl.create(:duke_authentication_service) }
  let(:new_user) { FactoryGirl.build(:user) }
  let (:first_time_user_token) {
    {
      'service_id' => subject.id,
      'uid' => SecureRandom.uuid,
      'display_name' => new_user.display_name,
      'first_name' => new_user.first_name,
      'last_name' => new_user.last_name,
      'email' => new_user.email
    }
  }
  let (:first_time_user_access_token) {
    JWT.encode(first_time_user_token, Rails.application.secrets.secret_key_base)
  }

  let(:existing_user) { FactoryGirl.create(:user) }
  let(:existing_user_auth) {
    FactoryGirl.create(:user_authentication_service,
    authentication_service: subject,
    user: existing_user)
  }
  let (:existing_user_token) {
    {
      'service_id' => subject.id,
      'uid' => existing_user_auth.uid,
      'display_name' => existing_user.display_name,
      'first_name' => existing_user.first_name,
      'last_name' => existing_user.last_name,
      'email' => existing_user.email
    }
  }
  let (:existing_user_access_token) {
    JWT.encode(existing_user_token, Rails.application.secrets.secret_key_base)
  }
  let (:invalid_access_token) {
    JWT.encode(existing_user_token, 'WrongSecret')
  }
  let (:existing_first_authenticating_user_token) {
    {
      'service_id' => subject.id,
      'uid' => existing_user.username,
      'display_name' => existing_user.display_name,
      'first_name' => existing_user.first_name,
      'last_name' => existing_user.last_name,
      'email' => existing_user.email
    }
  }
  let(:existing_first_authenticating_user) { existing_user }

  let (:existing_first_authenticating_access_token) {
    JWT.encode(existing_first_authenticating_user_token, Rails.application.secrets.secret_key_base)
  }

  it_behaves_like 'an authentication service'
end
