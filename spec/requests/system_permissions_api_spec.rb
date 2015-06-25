require 'rails_helper'
require 'jwt'
require 'securerandom'

describe DDS::V1::SystemPermissionsAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:user) { FactoryGirl.create(:user) }
  let(:auth_user) { FactoryGirl.create(:user, :with_auth_role) }
  let(:user_role_hash) {{
    'user' => auth_user.uuid,
    'auth_roles' => auth_user.auth_roles.collect { |role| 
      JSON.parse(AuthRoleSerializer.new(role).to_json) 
    }
  }}
  let(:auth_role) { FactoryGirl.create(:auth_role) }

  describe 'List system permissions' do
    it 'should return a list of users and auth_role objects' do
      expected_result = user_role_hash
      get '/api/v1/system/permissions', json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('results')
      expect(response_json['results']).to be_a Array
      expect(response_json['results']).to include(expected_result)
    end
  end

  describe 'Grant system permissions to user' do
    it 'should set auth_roles for a given user' do
      payload = {
        auth_roles: [auth_role.text_id]
      }
      expected_auth_roles = [JSON.parse(AuthRoleSerializer.new(auth_role).to_json)]
      put "/api/v1/system/permissions/#{user.id}", payload.to_json, json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('user')
      expect(response_json['user']).to eq(user.uuid)
      expect(response_json).to have_key('auth_roles')
      expect(response_json['auth_roles']).to be_a Array
      expect(response_json['auth_roles']).to eq(expected_auth_roles)
    end

    it 'should return validation errors for non-existent roles' do
      payload = {
        auth_roles: ['platform_user']
      }
      put "/api/v1/system/permissions/#{user.id}", payload.to_json, json_headers
      expect(response.status).to eq(400)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('error')
      expect(response_json['error']).to eq(400)
      expect(response_json).to have_key('reason')
      expect(response_json['reason']).to eq('validation failed')
    end
  end

  describe 'View system permissions for user' do
    it 'should get auth_roles for a given user' do
      get "/api/v1/system/permissions/#{auth_user.id}", json_headers
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).to have_key('user')
      expect(response_json['user']).to eq(auth_user.uuid)
      expect(response_json).to have_key('auth_roles')
      expect(response_json['auth_roles']).to be_a Array
      expect(response_json['auth_roles']).to eq(auth_user.auth_role_ids)
    end
  end

  describe 'Revoke system permissions for user' do
    it 'should delete all auth_roles for a given user' do
      delete "/api/v1/system/permissions/#{auth_user.id}", json_headers
      expect(response.status).to eq(204)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      auth_user.reload
      expect(auth_user.auth_role_ids).to be_nil
    end
  end
end
