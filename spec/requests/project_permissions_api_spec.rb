require 'rails_helper'

describe DDS::V1::ProjectPermissionsAPI do
  include_context 'with authentication'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:other_permission) { FactoryGirl.create(:project_permission) }
  let!(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:other_user) { FactoryGirl.create(:user) }

  let(:resource_class) { ProjectPermission }
  let(:resource_serializer) { ProjectPermissionSerializer }
  let!(:resource) { project_permission }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: resource.project) }
  let(:resource_project) { resource.project }
  let(:resource_user) { resource.user }

  describe 'Project Permissions collection' do
    let(:url) { "/api/v1/projects/#{resource_project.id}/permissions" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_permission,
          FactoryGirl.create(:project_permission, user: current_user)
        ] }
      end

      it 'should only include permissions for this project' do
        expect(other_permission).to be_persisted
        get url, nil, headers
        expect(response.body).not_to include(resource_serializer.new(other_permission).to_json)
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/permissions" }
        let(:resource_class) {'Project'}
      end
    end
  end

  describe 'Project Permission instance' do
    let(:url) { "/api/v1/projects/#{resource_project.id}/permissions/#{resource_user.id}" }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        auth_role: {id: auth_role.id}
      }}

      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:resource_user) { other_user }
        let(:new_object) {
          resource_class.find_by(project: resource_project, user: resource_user)
        }
      end

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/permissions/#{resource_user.id}" }
        let(:resource_class) {'Project'}
      end
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource_project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          auth_role: {id: 'invalid_role'}
        }}
        let(:resource_class) {'AuthRole'}
      end

      it_behaves_like 'an audited endpoint' do
        let(:with_audited_parent) { Project }
      end
    end

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource_project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{other_permission.project.id}/permissions/#{resource_user.id}" }
        let(:resource_class) {'ProjectPermission'}
      end
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/#{resource_project.id}/permissions/notexists_userid" }
        let(:resource_class) {'User'}
      end
      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 204 }
        let(:with_audited_parent) { Project}
      end
    end
  end
end
