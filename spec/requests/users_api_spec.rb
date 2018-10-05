require 'rails_helper'

describe DDS::V1::UsersAPI do
  let(:resource_class) { User }
  let(:resource) { FactoryBot.create(:user) }
  let(:resource_serializer) { UserSerializer }

  describe '/api/v1/user/api_token' do
    include_context 'common headers'
    let(:url) { '/api/v1/user/api_token' }
    let(:payload) { {access_token: access_token} }
    let(:headers) { common_headers }

    context 'duke_authentication_service' do
      let(:first_time_user) { FactoryBot.attributes_for(:user) }
      let(:first_time_user_token) {
        {
          'service_id' => authentication_service.service_id,
          'uid' => first_time_user[:username],
          'display_name' => first_time_user[:display_name],
          'first_name' => first_time_user[:first_name],
          'last_name' => first_time_user[:last_name],
          'email' => first_time_user[:email],
        }
      }
      let(:first_time_user_access_token) {
        JWT.encode(
          first_time_user_token,
          Rails.application.secrets.secret_key_base
        )
      }

      let(:existing_user_auth) {
        FactoryBot.create(:user_authentication_service,
        :populated,
        authentication_service: authentication_service)
      }
      let(:existing_user) { existing_user_auth.user }
      let (:existing_user_token) {
        {
          'service_id' => authentication_service.service_id,
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

      context 'as default authentication_service' do
        let(:authentication_service) { FactoryBot.create(:duke_authentication_service, :default) }
        it_behaves_like 'an authentication request endpoint'
      end

      context 'as identified authentication_service' do
        let(:authentication_service) { FactoryBot.create(:duke_authentication_service) }
        it_behaves_like 'an authentication request endpoint'
      end
    end

    context 'openid_authentication_service' do
      let(:first_time_user) { FactoryBot.attributes_for(:user) }
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

      let(:existing_user) { FactoryBot.create(:user) }
      let(:existing_user_auth) {
        FactoryBot.create(:user_authentication_service,
        authentication_service: authentication_service,
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
        FactoryBot.create(:user)
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

      include_context 'mocked openid request to', :authentication_service

      context 'as default authentication_service' do
        let(:authentication_service) { FactoryBot.create(:openid_authentication_service, :default , :openid_env) }
        it_behaves_like 'an authentication request endpoint'
      end

      context 'as identified authentication_service' do
        let(:authentication_service) { FactoryBot.create(:openid_authentication_service, :openid_env) }
        it_behaves_like 'an authentication request endpoint'
      end
    end
  end

  describe '/api/v1/users' do
    it_behaves_like 'a GET request' do
      include_context 'with authentication'
      let(:url) { "/api/v1/users" }
      let(:resource_serializer) {UserSerializer}

      let(:last_name_begins_with) { 'Abc' }
      let(:first_name_begins_with) { 'Xyz' }
      let(:full_name_contains) { 'xxxx' }
      let!(:users_with_last_name) {
        users = []
        3.times do
          nuser = FactoryBot.create(
            :user_authentication_service,
            :populated)
          nuser.user.update(
            last_name: "#{last_name_begins_with}#{Faker::Name.last_name}")
          users << nuser
        end
        users
      }

      let!(:users_with_first_name) {
        users = []
        3.times do
          nuser = FactoryBot.create(
            :user_authentication_service,
            :populated)
          nuser.user.update(
            :first_name => "#{first_name_begins_with}#{Faker::Name.first_name}")
          users << nuser
        end
        users
      }

      let!(:users_with_display_name) {
        users = []
        3.times do
          auser = FactoryBot.create(:user_authentication_service, :populated)
          auser.user.update(
            :display_name => "#{Faker::Name.first_name}#{full_name_contains} #{Faker::Name.last_name}"
          )
          users << auser
        end
        users
      }

      describe 'without filters' do
        let(:payload) {{}}
        let(:resource) { users_with_first_name[0].user }

        it_behaves_like 'a listable resource'
        it_behaves_like 'a paginated resource'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource'
      end

      describe 'with last_name_begins_with filter' do
        let(:payload) { {last_name_begins_with: last_name_begins_with} }
        let(:resource) { users_with_last_name[0].user }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { users_with_last_name.length }

          it 'should return a list of users whose last_name_begins_with' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).not_to be_empty
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['last_name']).to start_with(last_name_begins_with)
            end
          end
        end

        it_behaves_like 'a paginated resource' do
          let(:extras) { users_with_last_name }
          let(:expected_total_length) { users_with_last_name.length }
          let!(:paginated_payload) {
            payload.merge(pagination_parameters)
          }

          it 'should return a list of users whose last_name_begins_with' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).not_to be_empty
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['last_name']).to start_with(last_name_begins_with)
            end
          end
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource'
      end

      describe 'with first_name_begins_with' do
        let(:payload) { {first_name_begins_with: first_name_begins_with} }
        let(:resource) { users_with_first_name[0].user }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { users_with_first_name.length }

          it 'should return an list of users whose first_name_begins_with' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['first_name']).to start_with(first_name_begins_with)
            end
          end
        end

        it_behaves_like 'a paginated resource' do
          let(:extras) { users_with_first_name }
          let(:expected_total_length) { users_with_first_name.length }
          let!(:paginated_payload) {
            payload.merge(pagination_parameters)
          }

          it 'should return a list of users whose last_name_begins_with' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).not_to be_empty
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['first_name']).to start_with(first_name_begins_with)
            end
          end
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource'
      end

      describe 'with full_name_contains' do
        let(:payload) { {full_name_contains: full_name_contains} }
        let(:resource) { users_with_display_name[0].user }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { users_with_display_name.length }

          it 'should return an list of users whose full_name_contains' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['full_name']).to match(full_name_contains)
            end
          end
        end

        it_behaves_like 'a paginated resource' do
          let(:extras) { users_with_display_name }
          let(:expected_total_length) { users_with_display_name.length }
          let!(:paginated_payload) {
            payload.merge(pagination_parameters)
          }

          it 'should return a list of users whose last_name_begins_with' do
            is_expected.to eq(200)
            response_json = JSON.parse(response.body)
            expect(response_json).not_to be_empty
            expect(response_json).to have_key('results')
            returned_users = response_json['results']
            returned_users.each do |ruser|
              expect(ruser['full_name']).to match(full_name_contains)
            end
          end
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource'
      end

      describe 'with username' do
        let(:payload) { {username: resource.username} }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { 1 }
        end
      end
    end
  end

  describe 'User instance' do
    include_context 'with authentication'
    let(:url) { "/api/v1/users/#{resource_id}" }
    let(:resource_id) { resource.id }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end
  end
end
