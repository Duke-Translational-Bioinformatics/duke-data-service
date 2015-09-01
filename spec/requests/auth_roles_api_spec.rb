require 'rails_helper'

describe DDS::V1::AuthRolesAPI do
  let(:json_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
  let(:user_auth) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:user) { user_auth.user }
  let (:api_token) { user_auth.api_token }
  let(:json_headers_with_auth) {{'Authorization' => api_token}.merge(json_headers)}
  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:serialized_auth_role) { AuthRoleSerializer.new(auth_role).to_json }

  describe 'List authorization roles' do
    let(:url) { "/api/v1/project/auth_roles" }
    it 'should return a list of authorization roles for a given context' do
      get url, nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      response_json = JSON.parse(response.body)
      expect(response_json).not_to be_empty
      expect(response_json).to have_key('results')
      #Check for exact result
      expect(response_json['results']).to eq([
        {
         'id' => "project_admin",
         'name' => "Project Admin",
         'description' => "Can update project details, delete project, manage project level permissions and perform all file operations",
         'permissions' => [{ 'id' => "view_project"}, {'id' => "update_project"}, {'id' => "delete_project"}, {'id' => "manage_project_permissions"}, {'id' => "download_file"}, {'id' => "create_file"}, {'id' => "update_file"},
           {'id' => "delete_file"}],
         'contexts' => [ "project" ],
         'is_deprecated' => false
       },
        {
         'id' => "project_viewer",
         'name' => "Project Viewer",
         'description' => "Can only view project and file meta-data",
         'permissions' => [{ 'id' => "view_project" }],
         'contexts' => [ "project" ],
         'is_deprecated' => false
       },
        {
         'id' => "file_downloader",
         'name' => "File Downloader",
         'description' => "Can download files",
         'permissions' => [{ 'id' => "view_project"}, {'id' => "download_file" }],
         'contexts' => [ "project" ],
         'is_deprecated' => false
       },
        {
         'id' => "file_uploader",
         'name' => "File Uploader",
         'description' => "Can upload files",
         'permissions' => [{ 'id' => "view_project"}, {'id' => "create_file" }],
         'contexts' => [ "project" ],
         'is_deprecated' => false
       },
        {
         'id' => "file_editor",
         'name' => "File Editor",
         'description' => "Can view, download, create, update and delete files",
         'permissions' => [{ 'id' => "view_project"}, {'id' => "download_file"}, {'id' => "create_file"}, {'id' => "update_file"}, {'id' => "delete_file"}],
         'contexts' => [ "project" ],
         'is_deprecated' => false
        }
        ])
      #This isn't really necessary but may be kept if the above hard-coded hash is removed to keep it clean
      returned_auth_roles = response_json['results']
      returned_auth_roles.each do |rrole|
        expect(rrole).to have_key('id')
        expect(rrole).to have_key('name')
        expect(rrole).to have_key('description')
        expect(rrole).to have_key('permissions')
        expect(rrole).to have_key('contexts')
        expect(rrole).to have_key('is_deprecated')
      end
    end

    it 'should require an auth token' do
      get url, nil, json_headers
      expect(response.status).to eq(401)
    end
  end

  describe 'List details of a single authorization role' do
    let(:auth_role_id) { auth_role.text_id }
    let(:url) { "/api/v1/project/auth_roles/#{auth_role_id}" }
    it 'should return a json with a specific authorization role' do
      expect(auth_role).to be_persisted
      get url, nil, json_headers_with_auth
      expect(response.status).to eq(200)
      expect(response.body).to be
      expect(response.body).not_to eq('null')
      expect(response.body).to include(serialized_auth_role)
    end
    it 'should require an auth token' do
      get url, nil, json_headers
      expect(response.status).to eq(401)
    end
  end
end
