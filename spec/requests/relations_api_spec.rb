require 'rails_helper'

describe DDS::V1::RelationsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:view_auth_role) { FactoryGirl.create(:auth_role,
      id: "project_viewer",
      name: "Project Viewer",
      description: "Can only view project and file meta-data",
      contexts: %w(project),
      permissions: %w(view_project)
    )
  }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: view_auth_role, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:file_version) { FactoryGirl.create(:file_version, data_file: data_file) }
  let(:activity) { FactoryGirl.create(:activity, creator: current_user)}
  let(:other_user) { FactoryGirl.create(:user) }
  let(:other_users_activity) { FactoryGirl.create(:activity, creator: other_user) }

  describe 'Provenance Relations collection' do
    describe 'Create used relation' do
      let(:url) { "/api/v1/relations/used" }
      subject { post(url, payload.to_json, headers) }
      let(:resource_class) { UsedProvRelation }
      let(:called_action) { "POST" }
      let(:payload) {{
        activity: {
          id: activity.id
        },
        entity: {
          kind: file_version.kind,
          id: file_version.id
        }
      }}
      let(:resource_serializer) { UsedProvRelationSerializer }

      it_behaves_like 'a creatable resource'

      context 'with other users activity' do
        let(:payload) {{
          activity: {
            id: other_users_activity.id
          },
          entity: {
            kind: file_version.kind,
            id: file_version.id
          }
        }}
        it 'returns a Forbidden response' do
          is_expected.to eq(403)
          expect(response.status).to eq(403)
        end
      end

      context 'without activity in payload' do
        let(:payload) {{
          entity: {
            kind: file_version.kind,
            id: file_version.id
          }
        }}
        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end

      context 'without entity in payload' do
        let(:payload) {{
          activity: {
            id: activity.id
          }
        }}

        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource' do
        let(:resource_permission) { project_permission }
      end

      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 201 }
          let(:expected_auditable_type) { ProvRelation }
        end
      end
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
        let(:expected_auditable_type) { ProvRelation }
      end
    end # 'Create used relation'
  end # 'Provenance Relations Relations collection'
end
