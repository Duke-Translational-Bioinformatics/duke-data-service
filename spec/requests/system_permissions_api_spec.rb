require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::SystemPermissionsAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:user) { FactoryGirl.create(:user, :system_admin) }

  describe 'List system permissions' do
    it 'should return a list of users and auth_roles' do
      user_role_hash = {
        user: user.uuid,
        auth_roles: user.auth_roles
      }.stringify_keys
      get '/api/v1/system/permissions', json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('results')
      expect(response_json['results']).to be_a Array
      expect(response_json['results']).to include(user_role_hash)
    end
  end

  describe 'Grant system permissions to user' do
    it 'should set auth_roles for a given user' do
      put "/api/v1/system/permissions/#{user.id}", json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'View system permissions for user' do
    it 'should get auth_roles for a given user' do
      get "/api/v1/system/permissions/#{user.id}", json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end

  describe 'Revoke system permissions for user' do
    it 'should delete all auth_roles for a given user' do
      delete "/api/v1/system/permissions/#{user.id}", json_headers
      expect(response.status).to eq(204)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
    end
  end
end
