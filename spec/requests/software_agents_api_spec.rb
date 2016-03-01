require 'rails_helper'

describe DDS::V1::SoftwareAgentsAPI do
  include_context 'with authentication'

  let(:software_agent) { FactoryGirl.create(:software_agent, :with_key) }
  let(:deleted_software_agent) { FactoryGirl.create(:software_agent, :deleted) }
  let(:software_agent_stub) { FactoryGirl.build(:software_agent) }
  let(:system_permission) { FactoryGirl.create(:system_permission, user: current_user) }

  let(:resource_class) { SoftwareAgent }
  let(:resource_serializer) { SoftwareAgentSerializer }
  let!(:resource) { software_agent }
  let(:resource_stub) { software_agent_stub }
  let!(:resource_permission) { system_permission }

  describe 'SoftwareAgent collection' do
    let(:url) { "/api/v1/software_agents" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          deleted_software_agent
        ] }
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { "POST" }
      let(:payload) {{
        name: resource.name
      }}
      it_behaves_like 'a creatable resource' do
        let(:resource) { resource_stub }
        it 'should set creator to current_user and create a new api_key' do
          expect {
            is_expected.to eq(201)
          }.to change{ ApiKey.count }.by(1)
          expect(new_object.creator_id).to eq(current_user.id)
          expect(new_object.api_key).to be
        end
      end

      it_behaves_like 'an authenticated resource'

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          name: nil
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 201 }
      end
      it_behaves_like 'an audited endpoint' do
        let(:resource_class) { ApiKey }
        let(:expected_status) { 201 }
      end
    end
  end
  describe 'SoftwareAgent instance' do
    let(:url) { "/api/v1/software_agents/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let(:payload) {{
        name: resource_stub.name,
        description: resource_stub.description
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
            name: nil
        }}
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint'
      it_behaves_like 'a logically deleted resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 204 }
      end
      it_behaves_like 'a logically deleted resource'
    end

    describe 'api_key' do
      let(:url) { "/api/v1/software_agents/#{software_agent.id}/api_key" }
      let(:resource) { ApiKey.find(software_agent.api_key.id) }
      let(:resource_class) { ApiKey }
      let(:resource_serializer) { ApiKeySerializer }

      describe 'PUT' do
        subject { put(url, nil, headers) }
        it_behaves_like 'a regeneratable resource' do
          let(:new_resource) { ApiKey.where(software_agent_id: software_agent.id).take }
          let(:changed_key) { :key }
        end
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an audited endpoint' do
          let(:called_action) { 'PUT' }
          let(:expected_audits) { 2 }
        end
      end

      describe 'GET' do
        subject{ get(url, nil, headers) }
        it_behaves_like 'a viewable resource'
        it_behaves_like 'an authenticated resource'
      end
    end
  end

  describe 'Software Agent Access Token' do
    let(:url) { "/api/v1/software_agents/api_token" }
    let(:body) {
      {
        "agent_key": agent_key,
        "user_key": user_key
      }
    }
    subject{ post(url, body.to_json, headers) }

    context 'with valid agent_key and user_key' do
      let(:user_key) {
        FactoryGirl.create(:api_key, user_id: current_user.id).key
      }
      let(:agent_key) { resource.api_key.key }

      it 'should update user.last_login_at and return an api JWT' do
        original_last_login_at = current_user.last_login_at.to_i
        pre_time = DateTime.now.to_i
        is_expected.to eq(201)
        post_time = DateTime.now.to_i
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        token_wrapper = JSON.parse(response.body)
        expect(token_wrapper).to have_key('expires_on')
        expect(token_wrapper).to have_key('api_token')
        decoded_token = JWT.decode(token_wrapper['api_token'],
          Rails.application.secrets.secret_key_base
        )[0]
        expect(decoded_token).to be
        %w(id software_agent_id exp).each do |expected_key|
          expect(decoded_token).to have_key(expected_key)
        end
        expect(decoded_token['id']).to eq(current_user.id)
        expect(decoded_token['software_agent_id']).to eq(resource.id)
        existing_software_agent = SoftwareAgent.find(decoded_token['software_agent_id'])
        existing_user = User.find(decoded_token['id'])
        expect(existing_user).to be
        expect(existing_user.id).to eq(current_user.id)
        expect(existing_user.last_login_at.to_i).not_to eq(original_last_login_at)
        expect(existing_user.last_login_at.to_i).to be >= pre_time
        expect(existing_user.last_login_at.to_i).to be <= post_time
      end
    end

    context 'with missing agent_key' do
      let(:body) {
        {
          "user_key": FactoryGirl.create(:api_key, user_id: current_user.id).key
        }
      }

      it 'should respond with an error' do
        is_expected.to eq(400)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(400)
        expect(error_response['reason']).to eq('missing key or keys')
        expect(error_response['suggestion']).to eq('api_key and user_key are required')
      end
    end

    context 'with missing user_key' do
      let(:body) {
        {
          "agent_key": resource.api_key.key
        }
      }

      it 'should respond with an error' do
        is_expected.to eq(400)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(400)
        expect(error_response['reason']).to eq('missing key or keys')
        expect(error_response['suggestion']).to eq('api_key and user_key are required')
      end
    end

    context 'with invalid agent_key' do
      let(:user_key) {
        FactoryGirl.create(:api_key, user_id: current_user.id).key
      }
      let(:agent_key) { SecureRandom.hex }
      it 'should respond with an error' do
        is_expected.to eq(404)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(404)
        expect(error_response['reason']).to eq('invalid key')
        expect(error_response['suggestion']).to eq('ensure both keys are valid')
      end
    end

    context 'with invalid user_key' do
      let(:agent_key) { resource.api_key.key }
      let(:user_key) { SecureRandom.hex }
      it 'should respond with an error' do
        is_expected.to eq(404)
        expect(response.body).to be
        error_response = JSON.parse(response.body)
        %w(error reason suggestion).each do |expected_key|
          expect(error_response).to have_key expected_key
        end
        expect(error_response['error']).to eq(404)
        expect(error_response['reason']).to eq('invalid key')
        expect(error_response['suggestion']).to eq('ensure both keys are valid')
      end
    end
  end
end
