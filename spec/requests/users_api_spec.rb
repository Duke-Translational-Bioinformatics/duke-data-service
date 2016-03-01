require 'rails_helper'

describe DDS::V1::UsersAPI do
  let(:resource_class) { User }
  let(:resource) { FactoryGirl.create(:user) }
  let(:resource_serializer) { UserSerializer }

  describe 'get /api/v1/user/api_token' do
    let(:url) { '/api/v1/user/api_token' }

    describe 'for first time users' do
      include_context 'without authentication'
      let(:new_user) { FactoryGirl.attributes_for(:user) }
      let (:auth_service) { FactoryGirl.create(:authentication_service)}
      let(:new_user_token) {
        {
          'service_id' => auth_service.service_id,
          'uid' => FactoryGirl.attributes_for(:user_authentication_service)[:uid],
          'display_name' => new_user[:display_name],
          'first_name' => new_user[:first_name],
          'last_name' => new_user[:last_name],
          'email' => new_user[:email],
        }
      }
      let (:access_token) {
        JWT.encode(
          new_user_token,
          Rails.application.secrets.secret_key_base
        )
      }
      subject { get(url, {access_token: access_token}, common_headers) }
      let(:called_action) { "GET" }

      it 'should create a new User and return an api JWT when provided a JWT access_token encoded with our secret by a registered AuthenticationService' do
        expect(auth_service).to be_persisted
        pre_time = DateTime.now.to_i
        expect{
          expect {
            is_expected.to eq(200)
          }.to change{UserAuthenticationService.count}.by(1)
        }.to change{User.count}.by(1)
        post_time = DateTime.now.to_i
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['service_id']).to eq(auth_service.service_id)
        created_user = User.find(decoded_token['id'])
        expect(created_user).to be
        expect(created_user.display_name).to eq(new_user_token['display_name'])
        expect(created_user.username).to eq(new_user_token['uid'])
        expect(created_user.first_name).to eq(new_user_token['first_name'])
        expect(created_user.last_name).to eq(new_user_token['last_name'])
        expect(created_user.email).to eq(new_user_token['email'])
        expect(created_user.last_login_at.to_i).to be >= pre_time
        expect(created_user.last_login_at.to_i).to be <= post_time
        created_user_authentication_service = created_user.user_authentication_services.where(uid: new_user_token['uid']).first
        expect(created_user_authentication_service).to be
        expect(created_user_authentication_service.authentication_service_id).to eq(auth_service.id)
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:audit_should_include) {{}}

        it 'should set the newly created user as the user' do
          is_expected.to eq(expected_status)
          last_audit = Audited.audit_class.where(
            auditable_type: expected_auditable_type
          ).where(
            'comment @> ?', {action: called_action, endpoint: url}.to_json
          ).order(:created_at).last
          expect(last_audit.user).to be
          expect(last_audit.user.username).to eq(new_user_token['uid'])
        end
      end
    end

    describe 'for all users' do
      include_context 'with authentication'
      let (:user_token) {
        {
          'service_id' => user_auth.authentication_service.service_id,
          'uid' => user_auth.uid,
          'display_name' => current_user.display_name,
          'first_name' => current_user.first_name,
          'last_name' => current_user.last_name,
          'email' => current_user.email
        }
      }
      let (:access_token) {
        JWT.encode(user_token, Rails.application.secrets.secret_key_base)
      }
      let (:unknown_service_access_token) {
        JWT.encode({
          'service_id' => SecureRandom.uuid,
          'uid' => user_auth.uid,
          'display_name' => current_user.display_name,
          'first_name' => current_user.first_name,
          'last_name' => current_user.last_name,
          'email' => current_user.email,
        }, Rails.application.secrets.secret_key_base)
      }
      let (:wrong_secret_access_token) {
        JWT.encode(user_token, 'WrongSecret')
      }
      subject { get(url, {access_token: access_token}, common_headers) }

      it 'should update user.last_login_at and return an api JWT when provided a JWT access_token encoded with our secret by a registered AuthenticationService' do
        original_last_login_at = current_user.last_login_at.to_i
        pre_time = DateTime.now.to_i
        is_expected.to eq(200)
        post_time = DateTime.now.to_i
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('expires_on')
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id service_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['id']).to eq(current_user.id)
        expect(decoded_token['service_id']).to eq(user_auth.authentication_service.service_id)
        existing_user = User.find(decoded_token['id'])
        expect(existing_user).to be
        expect(existing_user.id).to eq(current_user.id)
        expect(existing_user.last_login_at.to_i).not_to eq(original_last_login_at)
        expect(existing_user.last_login_at.to_i).to be >= pre_time
        expect(existing_user.last_login_at.to_i).to be <= post_time
      end

      it 'should respond with an error when not provided an access_token' do
        get url, nil, common_headers
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
        original_last_login_at = current_user.last_login_at.to_i
        get url, {access_token: unknown_service_access_token}, common_headers
        expect(response.status).to eq(401)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(401)
        expect(error_response['reason']).to eq('invalid access_token')
        expect(error_response['suggestion']).to eq('authenticaton service not recognized')
        current_user.reload
        expect(current_user.last_login_at.to_i).to eq(original_last_login_at)
      end

      it 'should respond with an error when the token has not been signed by the secret_key_base' do
        original_last_login_at = current_user.last_login_at.to_i
        get url, {access_token: wrong_secret_access_token}, common_headers
        expect(response.status).to eq(401)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(401)
        expect(error_response['reason']).to eq('invalid access_token')
        expect(error_response['suggestion']).to eq('token not properly signed')
        current_user.reload
        expect(current_user.last_login_at.to_i).to eq(original_last_login_at)
      end
    end
  end

  describe 'get /api/v1/users' do
    include_context 'with authentication'
    let(:url) { "/api/v1/users" }
    let(:resource_serializer) {UserSerializer}

    let(:last_name_begins_with) { 'Abc' }
    let(:first_name_begins_with) { 'Xyz' }
    let(:full_name_contains) { 'xxxx' }
    let!(:users_with_last_name) {
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

    let!(:users_with_first_name) {
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

    let!(:users_with_display_name) {
      users = []
      5.times do
        auser = FactoryGirl.create(:user_authentication_service, :populated)
        auser.user.update(
          :display_name => "#{Faker::Name.first_name}#{full_name_contains} #{Faker::Name.last_name}"
        )
        users << auser
      end
      users
    }

    describe 'without filters' do
      subject { get(url, nil, headers) }
      let(:resource) { users_with_first_name[0].user }

      it_behaves_like 'a listable resource'
      it_behaves_like 'a paginated resource'
      it_behaves_like 'an authenticated resource'
    end

    describe 'with last_name_begins_with filter' do
      let(:payload) { {last_name_begins_with: last_name_begins_with} }
      subject { get(url, payload, headers) }
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
    end

    describe 'with first_name_begins_with' do
      let(:payload) { {first_name_begins_with: first_name_begins_with} }
      subject { get(url, payload, headers) }
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
    end

    describe 'with full_name_contains' do
      let(:payload) { {full_name_contains: full_name_contains} }
      subject { get(url, payload, headers) }
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
    end
  end

  describe 'User instance' do
    include_context 'with authentication'
    let(:url) { "/api/v1/users/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
    end
  end
end
