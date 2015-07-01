require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::ProjectsAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:project) { FactoryGirl.create(:project) }
  let(:project_stub) { FactoryGirl.build(:project) }

  describe 'Create a project' do
    it 'should store a project with the given payload' do
      payload = {
        name: project_stub.name,
        description: project_stub.description,
        pi_affiliate: {}
      }
      expect {
        post '/api/v1/projects', payload.to_json, json_headers
        expect(response.status).to eq(201)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
      }.to change{Project.count}.by(1)
    end
  end

  describe 'List projects' do
    it 'should return a list of projects the current user has view access on' do
      get '/api/v1/projects', json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'View project details' do
    it 'should return a json payload of the project associated with id' do
      get "/api/v1/projects/#{project.uuid}", json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'Update a project' do
    it 'should update the project associated with id using the supplied payload' do
      payload = {
        name: project_stub.name,
        description: project_stub.description
      }
      put "/api/v1/projects/#{project.uuid}", payload.to_json, json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'Delete a project' do
    it 'logically deletes the project associated with id' do
      expect(project).to be_persisted
      expect {
        delete "/api/v1/projects/#{project.uuid}", json_headers
        expect(response.status).to eq(204)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
      }.to_not change{Project.count}
      project.reload
      expect(project.is_deleted?).to be_truthy
    end
  end
end
