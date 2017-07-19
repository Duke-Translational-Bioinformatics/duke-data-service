require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::CurrentUserAPI do
  include_context 'with authentication'
  let(:resource) { current_user }
  let(:resource_class) { User }
  let(:resource_serializer) { UserSerializer }

  describe 'get /current_user' do
    let(:url) { '/api/v1/current_user' }
    subject { get(url, headers: headers) }

    context 'with valid api_token' do
      it_behaves_like 'a viewable resource'
    end

    context 'when not provided an api_token' do
      it_behaves_like 'an authenticated resource' do
        it 'should respond with an error' do
          is_expected.to eq(401)
          expect(response.body).to be
          error_response = JSON.parse(response.body)
          %w(error reason suggestion).each do |expected_key|
            expect(error_response).to have_key expected_key
          end
          expect(error_response).to have_key('code')
          expect(error_response['code']).to eq('not_provided')
          expect(error_response['error']).to eq(401)
          expect(error_response['reason']).to eq('no api_token')
          expect(error_response['suggestion']).to eq('you might need to login through an authenticaton service')
        end
      end
    end

    context 'when the api_token has not been signed by the secret_key_base' do
      let(:api_token) {
        JWT.encode({
          'id' => current_user.id,
          'authentication_service_id' => user_auth.authentication_service_id,
          'exp' => Time.now.to_i + 2.hours.to_i
        }, 'nottherightsecret')
      }

      it 'should respond with an error' do
        is_expected.to eq(401)
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

    context 'when the api_token has expired' do
      let(:api_token) {
        JWT.encode({
          'id' => current_user.id,
          'authentication_service_id' => user_auth.authentication_service_id,
          'exp' => Time.now.to_i - 2.hours.to_i,
        }, Rails.application.secrets.secret_key_base)
      }

      it 'should respond with an error' do
        is_expected.to eq(401)
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
    let(:url) { '/api/v1/current_user/usage' }
    subject { get(url, headers: headers) }
    let(:resource_serializer) { UserUsageSerializer }

    it_behaves_like 'a viewable resource'
    it_behaves_like 'an authenticated resource'
  end

  describe '/current_user/api_key' do
    let(:url) { '/api/v1/current_user/api_key' }
    let(:resource_class) { ApiKey }
    let(:resource_serializer) { ApiKeySerializer }

    describe 'PUT' do
      subject { put(url, headers: headers) }

      context 'without an existing token' do
        it_behaves_like 'a creatable resource' do
          let(:expected_response_status) {200}
          let(:new_object) {
            current_user.reload
            current_user.api_key
          }
        end
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an annotate_audits endpoint' do
          let(:called_action) { 'PUT' }
        end
        it_behaves_like 'a software_agent restricted resource'
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
        it_behaves_like 'an annotate_audits endpoint' do
          let(:called_action) { 'PUT' }
          let(:expected_audits) { 2 }
          before do
            expect(resource).to be_persisted
          end
        end
        it_behaves_like 'a software_agent restricted resource'
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      context 'without api_key' do
        it_behaves_like 'an identified resource' do
          let(:expected_suggestion) { "you must create an ApiKey" }
        end
      end

      context 'with existing api_key' do
        let!(:resource) {
          FactoryGirl.create(:api_key, user_id: current_user.id)
        }
        it_behaves_like 'a viewable resource'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent restricted resource'
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let!(:resource) {
        FactoryGirl.create(:api_key, user_id: current_user.id)
      }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
      it_behaves_like 'a software_agent restricted resource'
    end

  end
end
