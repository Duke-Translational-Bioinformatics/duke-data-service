require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::UserAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let (:auth_service) { FactoryGirl.create(:authentication_service) }

  describe 'get /api/v1/user/api_token' do
    describe 'for first time users' do
      let(:user) { FactoryGirl.build(:user) }
      let(:new_user_token) {
        {
          'service_id' => auth_service.uuid,
          'uid' => FactoryGirl.attributes_for(:user_authentication_service)[:uid],
          'display_name' => user.name,
          'email' => user.email,
        }
      }
      let (:access_token) {
        JWT.encode(new_user_token, Rails.application.secrets.secret_key_base)
      }

      it 'should create a new User and return an api JWT when provided a JWT access_token encoded with our secret by a registered AuthenticationService' do
        expect{
          expect {
            get '/api/v1/user/api_token', {access_token: access_token}, json_headers
          }.to change{UserAuthenticationService.count}.by(1)
        }.to change{User.count}.by(1)
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id authentication_service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['authentication_service_id']).to eq(auth_service.id)
        created_user = User.where(id: decoded_token['id']).first
        expect(created_user).to be
        expect(created_user.name).to eq(new_user_token['display_name'])
        expect(created_user.email).to eq(new_user_token['email'])
        created_user_authentication_service = created_user.user_authentication_services.where(uid: new_user_token['uid']).first
        expect(created_user_authentication_service).to be
        expect(created_user_authentication_service.authentication_service_id).to eq(auth_service.id)
      end
    end

    describe 'for all users' do
      let (:user) { FactoryGirl.create(:user) }
      let (:user_authentication_service) {
        FactoryGirl.create(:user_authentication_service,
          user: user,
          authentication_service: auth_service,
        )
      }
      let (:user_token) {
        {
          'service_id' => auth_service.uuid,
          'uid' => user_authentication_service.uid,
          'display_name' => user.name,
          'email' => user.email,
        }
      }
      let (:access_token) {
        JWT.encode(user_token, Rails.application.secrets.secret_key_base)
      }
      let (:unknown_service_access_token) {
        JWT.encode({
          'service_id' => SecureRandom.uuid,
          'uid' => user_authentication_service.uid,
          'display_name' => user.name,
          'email' => user.email,
        }, Rails.application.secrets.secret_key_base)
      }
      let (:wrong_secret_access_token) {
        JWT.encode(user_token, 'WrongSecret')
      }

      it 'should return an api JWT when provided a JWT access_token encoded with our secret by a registered AuthenticationService' do
        get '/api/v1/user/api_token', {access_token: access_token}, json_headers
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id authentication_service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['id']).to eq(user.id)
        expect(decoded_token['authentication_service_id']).to eq(auth_service.id)
        existing_user = User.where(id: decoded_token['id']).first
        expect(existing_user).to be
        expect(existing_user.id).to eq(user.id)
      end

      it 'should respond with an error when not provided an access_token' do
        get '/api/v1/user/api_token', nil, json_headers
        expect(response.status).to eq(400)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(400)
        expect(error_response['reason']).to eq('no access_token')
        expect(error_response['suggestion']).to eq('you might need to login through an authenticaton service')
      end

      it 'should respond with an error when the service_id in the access_token is not registered' do
        get '/api/v1/user/api_token', {access_token: unknown_service_access_token}, json_headers
        expect(response.status).to eq(401)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(401)
        expect(error_response['reason']).to eq('invalid access_token')
        expect(error_response['suggestion']).to eq('authenticaton service not recognized')
      end

      it 'should respond with an error when the token has not been signed by the secret_key_base' do
        get '/api/v1/user/api_token', {access_token: wrong_secret_access_token}, json_headers
        expect(response.status).to eq(401)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(401)
        expect(error_response['reason']).to eq('invalid access_token')
        expect(error_response['suggestion']).to eq('token not properly signed')
      end
    end
  end
end
