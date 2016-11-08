require 'rails_helper'

RSpec.describe DukeAuthenticationService, type: :model do
  subject { FactoryGirl.create(:duke_authentication_service) }
  it_behaves_like 'an authentication service'
  context 'get_user_for_access_token' do
    context 'with valid token' do
      context 'for first time user' do
        let(:new_user) { FactoryGirl.build(:user) }
        let (:user_token) {
          {
            'service_id' => subject.id,
            'uid' => SecureRandom.uuid,
            'display_name' => new_user.display_name,
            'first_name' => new_user.first_name,
            'last_name' => new_user.last_name,
            'email' => new_user.email
          }
        }
        let (:access_token) {
          JWT.encode(user_token, Rails.application.secrets.secret_key_base)
        }

        it 'should return an unpersisted user with an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
          returned_user = subject.get_user_for_access_token(access_token)
          expect(returned_user).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service).not_to be_nil
          expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          expect(returned_user.current_user_authenticaiton_service.authentication_service_id).to eq(subject.id)
        end
      end

      context 'for existing user' do
        let(:current_user) { FactoryGirl.create(:user) }
        context 'already authenticated with this authentication service' do
          let(:user_auth) {
            FactoryGirl.create(:user_authentication_service,
            authentication_service: subject,
            user: current_user)
          }
          let (:user_token) {
            {
              'service_id' => subject.id,
              'uid' => user_auth.uid,
              'display_name' => current_user.display_name,
              'first_name' => current_user.first_name,
              'last_name' => current_user.last_name,
              'email' => current_user.email
            }
          }
          let (:access_token) {
            expect(user_auth).to be_persisted
            expect(current_user).to be_persisted
            JWT.encode(user_token, Rails.application.secrets.secret_key_base)
          }

          it 'should return a persisted user with a persisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            expect(user_auth).to be_persisted
            expect(current_user).to be_persisted
            returned_user = subject.get_user_for_access_token(access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).to be_persisted
            expect(returned_user.current_user_authenticaiton_service.id).to eq(user_auth.id)
          end
        end

        context 'not authenticated with this authentication service' do
          let (:user_token) {
            {
              'service_id' => subject.id,
              'uid' => current_user.username,
              'display_name' => current_user.display_name,
              'first_name' => current_user.first_name,
              'last_name' => current_user.last_name,
              'email' => current_user.email
            }
          }
          let (:access_token) {
            expect(current_user).to be_persisted
            JWT.encode(user_token, Rails.application.secrets.secret_key_base)
          }

          it 'should return a persisted user with the an unpersisted user_authentication_service assigned to user.current_user_authenticaiton_service' do
            expect(current_user).to be_persisted
            returned_user = subject.get_user_for_access_token(access_token)
            expect(returned_user).to be_persisted
            expect(returned_user.current_user_authenticaiton_service).not_to be_nil
            expect(returned_user.current_user_authenticaiton_service).not_to be_persisted
          end
        end
      end
    end

    context 'with token not signed with our secret' do
      let(:current_user) { FactoryGirl.create(:user) }
      let(:user_auth) {
        FactoryGirl.create(:user_authentication_service,
        authentication_service: subject,
        user: current_user)
      }
      let (:user_token) {
        {
          'service_id' => subject.id,
          'uid' => user_auth.uid,
          'display_name' => current_user.display_name,
          'first_name' => current_user.first_name,
          'last_name' => current_user.last_name,
          'email' => current_user.email
        }
      }
      let (:wrong_secret_access_token) {
        JWT.encode(user_token, 'WrongSecret')
      }
      it {
        expect(user_auth).to be_persisted
        expect(current_user).to be_persisted
        expect {
          subject.get_user_for_access_token(wrong_secret_access_token)
        }.to raise_error(JWT::VerificationError)
      }
    end
  end
end
