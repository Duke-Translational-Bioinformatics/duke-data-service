require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::ProjectsAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }

  describe 'Create a project' do
    it 'should store a project with the given payload' do
      payload = {}
      post '/api/v1/projects', payload.to_json, json_headers
      expect(response.status).to eq(201)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
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
      project_id = 123
      get "/api/v1/projects/#{project_id}", json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'Update a project' do
    it 'should update the project associated with id using the supplied payload' do
      project_id = 123
      payload = {}
      put "/api/v1/projects/#{project_id}", payload, json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'Delete a project' do
    it 'logically deletes the project associated with id' do
      project_id = 123
      delete "/api/v1/projects/#{project_id}", json_headers
      expect(response.status).to eq(204)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      #project.reload
      #expect(project.is_deleted?).to be_truthy
    end
  end
end
