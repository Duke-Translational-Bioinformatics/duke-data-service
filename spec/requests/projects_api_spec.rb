require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::ProjectsAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:user_auth) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:user) { user_auth.user }
  let (:api_token) { user_auth.api_token }
  let(:json_headers_with_auth) {{'Authorization' => api_token}.merge(json_headers)}

  let(:project) { FactoryGirl.create(:project) }
  let(:serialized_project) { ProjectSerializer.new(project).to_json }
  let(:project_stub) { FactoryGirl.build(:project) }

  describe 'Create a project' do
    context 'with valid payload' do
      let(:payload) {{
          name: project_stub.name,
          description: project_stub.description,
          pi_affiliate: {}
        }}
      it 'should store a project with the given payload' do
        expect {
          post '/api/v1/projects', payload.to_json, json_headers_with_auth
          expect(response.status).to eq(201)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
        }.to change{Project.count}.by(1)

        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('id')
        expect(response_json['id']).to be
        expect(response_json).to have_key('name')
        expect(response_json['name']).to eq(payload[:name])
        expect(response_json).to have_key('description')
        expect(response_json['description']).to eq(payload[:description])
        expect(response_json).to have_key('is_deleted')
        expect(response_json['is_deleted']).to eq(false)

        new_project = Project.find(response_json['id'])
        expect(new_project.creator_id).to eq(user.id)
      end

      it 'should require an auth token' do
        expect {
          post '/api/v1/projects', payload.to_json, json_headers
          expect(response.status).to eq(400)
        }.not_to change{Project.count}
      end
    end

    context 'with invalid payload' do
      let(:payload) {{
          name: project.name,
          description: nil,
          pi_affiliate: {}
        }}
      before do
        expect(project).to be_persisted
        expect {
          post '/api/v1/projects', payload.to_json, json_headers_with_auth
        }.not_to change{Project.count}
      end
      it_behaves_like 'a validation failure'
    end
  end

  describe 'List projects' do
    it 'should return a list of projects the current user has view access on' do
      expect(project).to be_persisted
      get '/api/v1/projects', nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      expect(response.body).to include(serialized_project)
    end

    it 'should require an auth token' do
      get '/api/v1/projects', json_headers
      expect(response.status).to eq(400)
    end
  end

  describe 'View project details' do
    it 'should return a json payload of the project associated with id' do
      get "/api/v1/projects/#{project.id}", nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      expect(response.body).to include(serialized_project)
    end

    it 'should require an auth token' do
      get "/api/v1/projects/#{project.id}", json_headers
      expect(response.status).to eq(400)
    end
  end

  describe 'Update a project' do
    let(:project_uuid) { project.id }
    context 'with a valid payload' do
      let(:payload) {{
          name: project_stub.name,
          description: project_stub.description
      }}
      it 'should update the project associated with id using the supplied payload' do
        put "/api/v1/projects/#{project_uuid}", payload.to_json, json_headers_with_auth
        expect(response.status).to eq(200)
        expect(response.body).to be
        expect(response.body).not_to eq('null')

        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('id')
        expect(response_json['id']).to eq(project_uuid)
        expect(response_json).to have_key('name')
        expect(response_json['name']).to eq(payload[:name])
        expect(response_json).to have_key('description')
        expect(response_json['description']).to eq(payload[:description])
        expect(response_json).to have_key('is_deleted')
        expect(response_json['is_deleted']).to eq(project.is_deleted)
        project.reload
        expect(project.id).to eq(project_uuid)
        expect(project.name).to eq(payload[:name])
        expect(project.description).to eq(payload[:description])
      end

      it 'should require an auth token' do
        put "/api/v1/projects/#{project_uuid}", payload.to_json, json_headers
        expect(response.status).to eq(400)
      end
    end

    context 'with an invalid payload' do
      let(:payload) {{
          name: nil,
          description: nil,
      }}
      before do
        put "/api/v1/projects/#{project_uuid}", payload.to_json, json_headers_with_auth
      end
      it_behaves_like 'a validation failure'
    end
  end

  describe 'Delete a project' do
    it 'logically deletes the project associated with id' do
      expect(project).to be_persisted
      expect {
        delete "/api/v1/projects/#{project.id}", nil, json_headers_with_auth
        expect(response.status).to eq(204)
        expect(response.body).not_to eq('null')
        expect(response.body).to be
      }.to_not change{Project.count}
      project.reload
      expect(project.is_deleted?).to be_truthy
    end

    it 'should require an auth token' do
      delete "/api/v1/projects/#{project.id}", json_headers
      expect(response.status).to eq(400)
    end
  end
end
