require 'rails_helper'

describe DDS::V1::ProjectAffiliatesAPI do
  include_context 'with authentication'

  let(:affiliation) { FactoryGirl.create(:affiliation) }
  let(:project) { affiliation.project }
  let(:user) { affiliation.user }
  let(:project_role) { FactoryGirl.create(:project_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, :project_admin, user: current_user, project: project) }
  let(:other_affiliation) { FactoryGirl.create(:affiliation) }

  let(:resource_class) { Affiliation }
  let(:resource_serializer) { AffiliationSerializer }
  let!(:resource) { affiliation }
  let!(:resource_permission) { project_permission }

  describe 'Project Affiliate collection' do
    let(:url) { "/api/v1/projects/#{project_id}/affiliates" }
    let(:project_id) { project.id }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_affiliation
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
    end
  end

  describe 'Project Affiliate instance' do
    let(:url) { "/api/v1/projects/#{project_id}/affiliates/#{user_id}" }
    let(:project_id) { project.id }
    let(:user_id) { user.id }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        project_role: {id: project_role.id}
      }}

      it_behaves_like 'a creatable resource' do
        let(:user) { FactoryGirl.create(:user) }
        let(:expected_response_status) {200}
        let(:new_object) {
          resource_class.where(
            project_id: project.id,
            user_id: user.id,
            project_role_id: payload[:project_role][:id]
          ).last
        }
      end

      it_behaves_like 'an updatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          project_role: {id: nil}
        }}
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:audit_should_include) {
          {user: current_user, audited_parent: 'Project'}
        }
      end
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_auditable_type) { Project }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      it_behaves_like 'a removable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

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

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end
      it_behaves_like 'an identified resource' do
        let(:user_id) { "doesNotExist" }
        let(:resource_class) { User }
      end
    end
  end
end
