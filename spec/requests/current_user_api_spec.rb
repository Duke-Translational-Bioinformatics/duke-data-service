require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::CurrentUserAPI do
  describe 'get /current_user' do

    context 'with valid token' do
      include_context 'with authentication'
      it 'should return JSON serialized User' do
        get '/api/v1/current_user', nil, headers
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        expect(response.status).to eq(200)
        expect(response.body).to eq(UserSerializer.new(current_user, root: false).to_json)
      end
    end

    context 'no api_token at all' do
      include_context 'without authentication'
      it 'should respond with an error' do
        get '/api/v1/current_user', nil, headers
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
    end

    context 'api_token not signed by the secret_key_base' do
      include_context 'with authentication'
      let(:api_token) {
        JWT.encode({
          'id' => current_user.id,
          'authentication_service_id' => user_auth.authentication_service_id,
          'exp' => Time.now.to_i + 2.hours.to_i
        }, 'nottherightsecret')
      }

      it 'should respond with an error' do
        get '/api/v1/current_user', nil, headers
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
    end

    context 'with expired api_token' do
      include_context 'with authentication'
      let(:api_token) {
        JWT.encode({
          'id' => current_user.id,
          'authentication_service_id' => user_auth.authentication_service_id,
          'exp' => Time.now.to_i - 2.hours.to_i,
        }, Rails.application.secrets.secret_key_base)
      }

      it 'should respond with an error' do
        get '/api/v1/current_user', nil, headers
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
  end

  describe 'get /current_user/usage' do
    include_context 'with authentication'

    let(:url) { '/api/v1/current_user/usage' }
    subject { get(url, nil, headers) }
    let(:resource) { current_user }
    let(:resource_class) { User }
    let(:resource_serializer) { UserUsageSerializer }

    it_behaves_like 'a viewable resource'
    it_behaves_like 'an authenticated resource'
  end

  describe '/current_user/api_key' do
    include_context 'with authentication'
    let(:url) { '/api/v1/current_user/api_key' }

    describe 'PUT' do
      subject { put(url, nil, headers) }
      let(:resource_class) { ApiKey }
      let(:resource_serializer) { ApiKeySerializer }

      context 'without an existing token' do
        it_behaves_like 'a creatable resource' do
          let(:expected_response_status) {200}
          let(:new_object) {
            current_user.reload
            current_user.api_key
          }
        end
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an audited endpoint' do
          let(:called_action) { 'PUT' }
        end
      end

      context 'with existing token' do
        let(:resource) {
          FactoryGirl.create(:api_key, user_id: current_user.id)
        }
        it_behaves_like 'a regeneratable resource' do
          let(:new_resource) {
            current_user.api_key
          }
          let(:changed_key) { :key }
        end
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an audited endpoint' do
          let(:called_action) { 'PUT' }
          let(:expected_audits) { 2 }
          before do
            expect(resource).to be_persisted
          end
        end
      end
    end
  end
end
