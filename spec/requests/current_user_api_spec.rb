require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::CurrentUserAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let (:auth_service) { FactoryGirl.create(:authentication_service) }
  let (:user) { FactoryGirl.create(:user) }
  let (:user_authentication_service) {
    FactoryGirl.create(:user_authentication_service,
      user: user,
      authentication_service: auth_service,
    )
  }
  let (:api_token) { user_authentication_service.api_token }

  describe 'get /current_user' do
    let(:wrong_secret_api_token) {
      JWT.encode({
        'id' => user.id,
        'authentication_service_id' => user_authentication_service.authentication_service_id,
        'exp' => Time.now.to_i + 2.hours.to_i
      }, 'nottherightsecret')
    }
    let(:expired_api_token) {
      JWT.encode({
        'id' => user.id,
        'authentication_service_id' => user_authentication_service.authentication_service_id,
        'exp' => Time.now.to_i - 2.hours.to_i,
      }, Rails.application.secrets.secret_key_base)
    }

    it 'should return JSON serialized User when provided a valid api_token as the Authorization Header' do
      get '/api/v1/current_user', nil, {'Authorization' => api_token}.merge(json_headers)
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      expect(response.status).to eq(200)
      expect(response.body).to eq(UserSerializer.new(user, root: false).to_json)
    end

    it 'should respond with an error when not provided an api_token' do
      get '/api/v1/current_user', nil, json_headers
      expect(response.status).to eq(401)
      expect(response.body).to be
      error_response = JSON.parse(response.body)
      %w(error reason suggestion).each do |expected_key|
        expect(error_response).to have_key expected_key
      end
      expect(error_response['error']).to eq(401)
      expect(error_response['reason']).to eq('no api_token')
      expect(error_response['suggestion']).to eq('you might need to login through an authenticaton service')
    end

    it 'should respond with an error when the api_token has not been signed by the secret_key_base' do
      get '/api/v1/current_user', nil, {'Authorization' => wrong_secret_api_token}.merge(json_headers)
      expect(response.status).to eq(401)
      expect(response.body).to be
      error_response = JSON.parse(response.body)
      %w(error reason suggestion).each do |expected_key|
        expect(error_response).to have_key expected_key
      end
      expect(error_response['error']).to eq(401)
      expect(error_response['reason']).to eq('invalid api_token')
      expect(error_response['suggestion']).to eq('token not properly signed')
    end

    it 'should respond with an error when the api_token has expired' do
      get '/api/v1/current_user', nil, {'Authorization' => expired_api_token}.merge(json_headers)
      expect(response.status).to eq(401)
      expect(response.body).to be
      error_response = JSON.parse(response.body)
      %w(error reason suggestion).each do |expected_key|
        expect(error_response).to have_key expected_key
      end
      expect(error_response['error']).to eq(401)
      expect(error_response['reason']).to eq('expired api_token')
      expect(error_response['suggestion']).to eq('you need to login with your authenticaton service')
    end
  end

  describe 'get /current_user/usage' do
    include_context 'with authentication'

    let(:url) { '/api/v1/current_user/usage' }
    subject { get(url, nil, headers) }
    let(:resource) { user }
    let(:resource_class) { User }
    let(:resource_serializer) { UserUsageSerializer }

    it_behaves_like 'a viewable resource'
    it_behaves_like 'an authenticated resource'
  end

  describe 'get /current_user/api_key' do
    include_context 'with authentication'

    let(:url) { '/api/v1/current_user/api_key' }
    subject { put(url, nil, headers) }
    let(:resource_class) { UserApiSecret }
    let(:resource_serializer) { UserApiSecretSerializer }

    context 'without an existing token' do
      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:new_object) {
          current_user.reload
          current_user.user_api_secret
        }
      end
      it_behaves_like 'an authenticated resource'
    end

    context 'with existing token' do
      let(:resource) {
        FactoryGirl.create(:user_api_secret, user_id: current_user.id)
      }
      it_behaves_like 'a regeneratable resource' do
        let(:new_resource) {
          current_user.user_api_secret
        }
        let(:changed_key) { :key }
      end
      it_behaves_like 'an authenticated resource'
    end
  end
end
