require 'rails_helper'

describe DDS::V1::ProjectAffiliatesAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:user_auth) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:user) { user_auth.user }
  let (:api_token) { user_auth.api_token }
  let(:json_headers_with_auth) {{'Authorization' => api_token}.merge(json_headers)}

  let(:membership) { FactoryGirl.create(:membership) }
  let(:project) { FactoryGirl.create(:project) }
  #let(:serialized_project) { ProjectSerializer.new(project).to_json }
  #let(:project_stub) { FactoryGirl.build(:project) }

  describe 'Create a project' do
    let(:payload) {{
        user: {id: user.uuid},
        external_person: nil,
        project_roles: [{id: 'principal_investigator'}]
      }}
    it 'should store a project affiilation with the given payload' do
      expect {
        post "/api/v1/project/#{project.uuid}/affiliates", payload.to_json, json_headers_with_auth
        expect(response.status).to eq(201)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
      }.to change{Membership.count}.by(1)

      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('id')
      expect(response_json['id']).to be
      expect(response_json).to have_key('is_external')
      expect(response_json['is_external']).to eq(false)
      expect(response_json).to have_key('project')
      expect(response_json['project']).to eq({'id' => project.uuid})
      expect(response_json).to have_key('user')
      #TODO: Check for serialized user and project_roles
      #expect(response_json['user']).to eq(payload[:user])
      expect(response_json).to have_key('external_person')
      expect(response_json['external_person']).to eq(nil)
      expect(response_json).to have_key('project_roles')
      #expect(response_json['project_roles']).to eq(payload[:project_roles])
    end

    it 'should require an auth token' do
      expect {
        post "/api/v1/project/#{project.uuid}/affiliates", payload.to_json, json_headers
        expect(response.status).to eq(400)
      }.not_to change{Membership.count}
    end
  end

  describe 'List project affiliates' do
    it 'should return a list of affiliates for a given project' do
      expect(project).to be_persisted
      get "/api/v1/project/#{project.uuid}/affiliates", nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      #TODO: Check for serialized affiliate
      #expect(response.body).to include(serialized_affiliate)
    end

    it 'should require an auth token' do
      get "/api/v1/project/#{project.uuid}/affiliates", nil, json_headers
      expect(response.status).to eq(400)
    end
  end

  describe 'View project affiliate details' do
    let(:affiliate_uuid) { membership.id }
    it 'should return a json payload of the affiliate associated with id' do
      #TODO: Populate affiliate_uuid
      get "/api/v1/project/#{project.uuid}/affiliates/#{affiliate_uuid}", nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      #TODO: Check for serialized affiliate
      #expect(response.body).to include(serialized_affiliate)
    end

    it 'should require an auth token' do
      get "/api/v1/project/#{project.uuid}/affiliates/#{affiliate_uuid}", nil, json_headers
      expect(response.status).to eq(400)
    end
  end

  describe 'Update a project affiliate' do
    let(:project_uuid) { membership.project.uuid }
    let(:affiliate_uuid) { membership.id }
    let(:payload) {{
        user: {id: user.uuid},
        external_person: nil,
        project_roles: [{id: 'research_coordinator'}]
    }}
    it 'should update the project affiliate associated with id using the supplied payload' do
      put "/api/v1/project/#{project_uuid}/affiliates/#{affiliate_uuid}", payload.to_json, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')

      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('id')
      expect(response_json['id']).to be
      expect(response_json).to have_key('is_external')
      expect(response_json['is_external']).to eq(false)
      expect(response_json).to have_key('project')
      expect(response_json['project']).to eq({'id' => project_uuid})
      expect(response_json).to have_key('user')
      #TODO: Check for serialized user and project_roles
      #expect(response_json['user']).to eq(payload[:user])
      expect(response_json).to have_key('external_person')
      expect(response_json['external_person']).to eq(nil)
      expect(response_json).to have_key('project_roles')
      #expect(response_json['project_roles']).to eq(payload[:project_roles])
      membership.reload
      expect(membership.id).to eq(affiliate_uuid)
      expect(membership.project.uuid).to eq(project_uuid)
      #expect(membership.user.uuid).to eq(payload[:user][:id])
    end

    it 'should require an auth token' do
      put "/api/v1/project/#{project_uuid}/affiliates/#{affiliate_uuid}", payload.to_json, json_headers
      expect(response.status).to eq(400)
    end
  end

  describe 'Delete a project affiliate' do
    let(:affiliate_uuid) { membership.id }
    it 'remove the project affiliation associated with id' do
      expect(membership).to be_persisted
      expect {
        delete "/api/v1/project/#{project.uuid}/affiliates/#{affiliate_uuid}", nil, json_headers_with_auth
        expect(response.status).to eq(204)
        expect(response.body).not_to eq('null')
        expect(response.body).to be
      }.to change{Membership.count}.by(-1)
    end

    it 'should require an auth token' do
      delete "/api/v1/project/#{project.uuid}/affiliates/#{affiliate_uuid}", nil, json_headers
      expect(response.status).to eq(400)
    end
  end
end
