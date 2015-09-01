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
          'display_name' => user.display_name,
          'first_name' => user.first_name,
          'last_name' => user.last_name,
          'email' => user.email,
        }
      }
      let (:access_token) {
        JWT.encode(
          new_user_token,
          Rails.application.secrets.secret_key_base
        )
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
        created_user = User.find(decoded_token['id'])
        expect(created_user).to be
        expect(created_user.display_name).to eq(new_user_token['display_name'])
        expect(created_user.first_name).to eq(new_user_token['first_name'])
        expect(created_user.last_name).to eq(new_user_token['last_name'])
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
          'display_name' => user.display_name,
          'first_name' => user.first_name,
          'last_name' => user.last_name,
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
          'display_name' => user.display_name,
          'first_name' => user.first_name,
          'last_name' => user.last_name,
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
        existing_user = User.find(decoded_token['id'])
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

  describe 'get /api/v1/users' do
    let(:url) { "/api/v1/users" }
    let(:user_auth) { FactoryGirl.create(:user_authentication_service, :populated) }
    let(:user) { user_auth.user }
    let (:api_token) { user_auth.api_token }
    let(:json_headers_with_auth) {{'Authorization' => api_token}.merge(json_headers)}
    let(:last_name_begins_with) { 'Abc' }
    let(:first_name_begins_with) { 'Xyz' }
    let(:display_name_contains) { 'aso' }
    let(:users_with_last_name) {
      users = []
      5.times do
        nuser = FactoryGirl.create(
          :user_authentication_service,
          :populated)
        nuser.user.update(
          last_name: "#{last_name_begins_with}#{Faker::Name.last_name}")
        users << nuser
      end
      users
    }

    let(:users_with_first_name) {
      users = []
      5.times do
        nuser = FactoryGirl.create(
          :user_authentication_service,
          :populated)
        nuser.user.update(
          :first_name => "#{first_name_begins_with}#{Faker::Name.first_name}")
        users << nuser
      end
      users
    }

    let(:users_with_display_name) {
      users = []
      auser = FactoryGirl.create(:user_authentication_service, :populated)
      auser.user.update(
        :display_name => "#{Faker::Name.first_name}#{display_name_contains} #{Faker::Name.last_name}"
      )
      users << auser
      buser = FactoryGirl.create(:user_authentication_service, :populated)
      buser.user.update(
        :display_name => "#{Faker::Name.first_name} #{display_name_contains}#{Faker::Name.last_name}"
      )
      users << buser
      cuser = FactoryGirl.create(:user_authentication_service, :populated)
      cuser.user.update(
        :display_name => "#{display_name_contains}#{Faker::Name.first_name} #{Faker::Name.last_name}"
      )
      users << cuser
      duser = FactoryGirl.create(:user_authentication_service, :populated)
      duser.user.update(
        :display_name => "#{Faker::Name.first_name} #{Faker::Name.last_name}#{display_name_contains}"
      )
      users << duser
      users
    }

    it 'should return all users when not provided a filter' do
      expect(users_with_first_name.length + users_with_first_name.length).to be <= 10
      get url, nil, json_headers_with_auth
      expect(response.status).to eq(200);
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('results')
      returned_users = response_json['results']
      expect(returned_users.length).to eq(User.all.count)
    end

    it 'should return an list of users whose last_name_begins_with' do
      expect(users_with_last_name.length).to be >= 5
      get url, {last_name_begins_with: last_name_begins_with}, json_headers_with_auth
      expect(response.status).to eq(200);
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).not_to be_empty
      expect(response_json).to have_key('results')
      returned_users = response_json['results']
      expect(returned_users).not_to be_empty
      expect(returned_users.length).to be >= users_with_last_name.length
      returned_users.each do |ruser|
        expect(ruser['last_name']).to start_with(last_name_begins_with)
      end
    end

    it 'should return an list of users whose first_name_begins_with' do
      expect(users_with_first_name.length).to be >= 5
      get url, {first_name_begins_with: first_name_begins_with}, json_headers_with_auth
      expect(response.status).to eq(200);
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('results')
      returned_users = response_json['results']
      expect(returned_users).not_to be_empty
      expect(returned_users.length).to be >= users_with_first_name.length
      returned_users.each do |ruser|
        expect(ruser['first_name']).to start_with(first_name_begins_with)
      end
    end

    it 'should return an list of users whose display_name_contains' do
      expect(users_with_display_name.length).to be >= 4
      get url, {display_name_contains: display_name_contains}, json_headers_with_auth
      expect(response.status).to eq(200);
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('results')
      returned_users = response_json['results']
      expect(returned_users).not_to be_empty
      expect(returned_users.length).to be >= users_with_display_name.length
      returned_users.each do |ruser|
        expect(ruser['full_name']).to match(display_name_contains)
      end
    end

    it 'should require an auth token' do
      get url, nil, json_headers
      expect(response.status).to eq(401)
    end
  end
end
