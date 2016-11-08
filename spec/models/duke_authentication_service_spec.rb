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
  let (:existing_first_authenticating_access_token) {
    JWT.encode(existing_first_authenticating_user_token, Rails.application.secrets.secret_key_base)
  }

  it_behaves_like 'an authentication service'

  context 'get_user_for_access_token' do
    context 'with valid token' do
      context 'for first time user' do
        it 'should return an unpersisted user with an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
          returned_user = subject.get_user_for_access_token(first_time_user_access_token)
          expect(returned_user).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service).not_to be_nil
          expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service.authentication_service_id).to eq(subject.id)
        end
      end

      context 'for existing user' do
        context 'already authenticated with this authentication service' do
          it 'should return a persisted user with a persisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            returned_user = subject.get_user_for_access_token(existing_user_access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.id).to eq(existing_user.id)
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).to be_persisted
            expect(returned_user.current_user_authenticaiton_service.id).to eq(existing_user_auth.id)
          end
        end

        context 'not authenticated with this authentication service' do
          it 'should return a persisted user with the an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            returned_user = subject.get_user_for_access_token(existing_first_authenticating_access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.id).to eq(existing_user.id)
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          end
        end
      end
    end

    context 'with invalid token' do
      it {
        expect {
          subject.get_user_for_access_token(invalid_access_token)
        }.to raise_error(InvalidAccessTokenException)
      }
    end
  end
end
