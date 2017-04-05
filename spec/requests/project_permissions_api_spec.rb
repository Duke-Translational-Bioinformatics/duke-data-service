require 'rails_helper'

describe DDS::V1::ProjectPermissionsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, project: project) }
  let(:other_permission) { FactoryGirl.create(:project_permission) }
  let!(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:other_user) { FactoryGirl.create(:user) }

  let(:resource_class) { ProjectPermission }
  let(:resource_serializer) { ProjectPermissionSerializer }
  let!(:resource) { project_permission }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:resource_project) { project }
  let(:resource_user) { resource.user }

  describe 'Project Permissions collection' do
    let(:url) { "/api/v1/projects/#{project_id}/permissions" }
    let(:project_id) { resource_project.id }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_permission,
          FactoryGirl.create(:project_permission, :project_admin, user: current_user)
        ] }
      end

      it 'should only include permissions for this project' do
        expect(other_permission).to be_persisted
        get url, nil, headers
        expect(response.body).not_to include(resource_serializer.new(other_permission).to_json)
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { resource_project }
      end
    end
  end

  describe 'Project Permission instance' do
    let(:url) { "/api/v1/projects/#{project_id}/permissions/#{user_id}" }
    let(:project_id) { resource_project.id }
    let(:user_id) { resource_user.id }

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
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
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          auth_role: {id: 'invalid_role'}
        }}
        let(:resource_class) { AuthRole }
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:audit_should_include) {
          {user: current_user, audited_parent: 'Project'}
        }
      end
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_auditable_type) { Project }
      end

      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint' do
          let(:audit_should_include) {
            {user: current_user, software_agent: software_agent, audited_parent: 'Project'}
          }
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_auditable_type) { Project }
        end
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { resource_project }
      end

      context 'permission belongs to current user' do
        let(:resource) { resource_permission }
        it { is_expected.to eq (403) }
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { other_permission.project.id }
        let(:resource_class) {'ProjectPermission'}
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { resource_project }
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { other_permission.project.id }
        let(:resource_class) {'ProjectPermission'}
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
        let(:audit_should_include) {
          {user: current_user, audited_parent: 'Project'}
        }
      end
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
        let(:expected_auditable_type) { Project }
      end

      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 204 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
          let(:audit_should_include) {
            {user: current_user, audited_parent: 'Project', software_agent: software_agent}
          }
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
          let(:expected_auditable_type) { Project }
        end
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { resource_project }
      end
    end
  end
end
