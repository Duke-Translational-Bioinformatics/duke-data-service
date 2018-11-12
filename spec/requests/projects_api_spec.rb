require 'rails_helper'

describe DDS::V1::ProjectsAPI do
  include_context 'with authentication'
  let(:project_admin_role) { FactoryBot.create(:auth_role, :project_admin) }
  let(:project) { FactoryBot.create(:project) }
  let(:deleted_project) { FactoryBot.create(:project, :deleted) }
  let(:other_project) { FactoryBot.create(:project) }
  let(:project_stub) { FactoryBot.build(:project) }
  let(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }

  let(:resource_class) { Project }
  let(:resource_serializer) { ProjectSerializer }
  let!(:resource) { project }
  let!(:resource_permission) { project_permission }

  before do
    expect(project_admin_role).to be_persisted
  end

  describe 'Project collection' do
    let(:url) { "/api/v1/projects" }
    let(:payload) {{}}

    it_behaves_like 'a GET request' do
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          deleted_project,
          other_project
        ] }
      end

      context 'with slugged project' do
        let(:project) { FactoryBot.create(:project, :with_slug) }
        let(:non_slug_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user) }
        let(:non_slug) { non_slug_permission.project.tap {|p| p.update_attribute(:slug, nil)} }
        before(:each) do
          expect(project).to be_persisted
          expect(non_slug).to be_persisted
          expect(non_slug.slug).to be_nil
        end

        context 'slug param not set' do
          it_behaves_like 'a listable resource' do
            let(:expected_resources) { [
              project,
              non_slug
            ] }
            let(:unexpected_resources) { [
              deleted_project,
              other_project
            ] }
          end
          it_behaves_like 'a listable resource' do
            let(:payload) {{slug: ''}}
            let(:expected_resources) { [
              project,
              non_slug
            ] }
            let(:unexpected_resources) { [
              deleted_project,
              other_project
            ] }
          end
        end

        context 'slug param set to existing slug' do
          let(:payload) {{slug: project.slug}}
          it_behaves_like 'a listable resource' do
            let(:expected_resources) { [
              project
            ] }
            let(:unexpected_resources) { [
              deleted_project,
              other_project
            ] }
          end
        end

        context 'nonexistent slug' do
          let(:payload) {{slug: 'NONEXISTENT-SLUG'}}
          it 'returns an empty results array' do
            is_expected.to eq(expected_response_status)
            response_json = JSON.parse(response.body)
            expect(response_json).to have_key('results')
            returned_results = response_json['results']
            expect(returned_results).to be_a(Array)
            expect(returned_results).to be_empty
          end
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { Project.all.count }
        let(:extras) { FactoryBot.create_list(:project_permission, 5, :project_admin, user: current_user) }
      end
    end

    describe 'POST' do
      # subject { post(url, params: payload.to_json, headers: headers) }
      # let(:called_action) { "POST" }
      let(:payload) {{
        name: resource.name,
        slug: project_slug,
        description: resource.description
      }}
      let(:project_slug) { 'a_project_slug' }
      include_context 'with job runner', ProjectStorageProviderInitializationJob

      context 'with queued ActiveJob' do
        it_behaves_like 'a POST request' do
          it_behaves_like 'a creatable resource' do
            let(:resource) { project_stub }
            let(:expected_response_status) { 202 }
            it 'should set creator to current_user and make them a project_admin, and queue an ActiveJob' do
              expect {
                is_expected.to eq(expected_response_status)
              }.to change{ ProjectPermission.count }.by(1)
              response_json = JSON.parse(response.body)
              expect(response_json).to have_key('id')
              new_object = resource_class.find(response_json['id'])
              expect(new_object.creator_id).to eq(current_user.id)
              project_admin_role = AuthRole.where(id: 'project_admin').first
              project_admin_permission = new_object.project_permissions.where(user_id: current_user.id, auth_role_id: project_admin_role.id).first
              expect(project_admin_permission).to be
            end

            it 'sets project slug' do
              is_expected.to eq(expected_response_status)
              response_json = JSON.parse(response.body)
              expect(response_json).to have_key('id')
              new_object = resource_class.find(response_json['id'])
              expect(new_object.slug).to eq(project_slug)
            end
          end

          context 'without slug set' do
            let(:payload) {{
              name: resource.name,
              description: resource.description
            }}
            it_behaves_like 'a creatable resource' do
              let(:resource) { project_stub }
              let(:expected_response_status) { 202 }

              it 'sets project slug' do
                is_expected.to eq(expected_response_status)
                response_json = JSON.parse(response.body)
                expect(response_json).to have_key('id')
                new_object = resource_class.find(response_json['id'])
                expect(new_object.slug).not_to be_blank
              end
            end
          end

          it_behaves_like 'an authenticated resource'

          it_behaves_like 'a validated resource' do
            let!(:payload) {{
              name: resource.name,
              description: nil
            }}
            it 'should not persist changes' do
              expect(resource).to be_persisted
              expect {
                is_expected.to eq(400)
              }.not_to change{resource_class.count}
            end
          end

          context 'with non-unique slug' do
            before { FactoryBot.create(:project, slug: project_slug) }
            it_behaves_like 'a validated resource'
          end

          it_behaves_like 'an annotate_audits endpoint' do
            let(:resource) { project_stub }
            let(:expected_response_status) { 202 }
            let(:expected_audits) { 2 }
          end

          it_behaves_like 'an annotate_audits endpoint' do
            let(:resource) { project_stub }
            let(:expected_auditable_type) { ProjectPermission }
            let(:expected_response_status) { 202 }
            let(:audit_should_include) {
              {user: current_user, audited_parent: 'Project'}
            }
          end
          it_behaves_like 'a software_agent accessible resource' do
            let(:resource) { project_stub }
            let(:expected_response_status) { 202 }
            it_behaves_like 'an annotate_audits endpoint' do
              let(:resource) { project_stub }
              let(:expected_response_status) { 202 }
              let(:expected_audits) { 2 }
            end

            it_behaves_like 'an annotate_audits endpoint' do
              let(:resource) { project_stub }
              let(:expected_auditable_type) { ProjectPermission }
              let(:expected_response_status) { 202 }
              let(:audit_should_include) {
                {user: current_user, audited_parent: 'Project', software_agent: software_agent}
              }
            end
          end
        end
      end
    end
  end

  describe 'Project instance' do
    let(:url) { "/api/v1/projects/#{resource_id}" }
    let(:resource_id) { resource.id }

    describe 'GET' do
      let(:payload) {{}}

      it_behaves_like 'a GET request' do
        it_behaves_like 'a viewable resource'

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an authorized resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) { "doesNotExist" }
        end
      end
    end

    describe 'PUT' do
      let(:payload) {{
        name: project_stub.name,
        slug: project_slug,
        description: project_stub.description
      }}
      let(:project_slug) { 'a_project_slug' }

      it_behaves_like 'a PUT request', response_status: 200 do
        it_behaves_like 'an updatable resource' do
          it 'sets project slug' do
            is_expected.to eq(expected_response_status)
            resource.reload
            expect(resource.slug).to eq(project_slug)
          end
        end

        context 'without slug set' do
          let(:payload) {{
            name: project_stub.name,
            description: project_stub.description
          }}
          it_behaves_like 'an updatable resource'
          it 'returns without changing slug' do
            original_slug = resource.slug
            is_expected.to eq(expected_response_status)
            resource.reload
            expect(resource.slug).to eq(original_slug)
          end
        end

        context 'with only slug set' do
          let(:payload) {{
            slug: project_slug
          }}
          it_behaves_like 'an updatable resource'
        end

        context 'with blank slug set' do
          let(:payload) {{
            slug: ''
          }}
          it 'returns without changing slug' do
            original_slug = resource.slug
            is_expected.to eq(expected_response_status)
            resource.reload
            expect(resource.slug).to eq(original_slug)
          end
        end

        context 'with non-unique slug' do
          before { FactoryBot.create(:project, slug: project_slug) }
          it_behaves_like 'a validated resource'
        end

        it_behaves_like 'a validated resource' do
          let(:payload) {{
              name: nil,
              description: nil,
          }}
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an authorized resource'
        it_behaves_like 'an annotate_audits endpoint'
        it_behaves_like 'a software_agent accessible resource' do
          it_behaves_like 'an annotate_audits endpoint'
        end
        it_behaves_like 'a logically deleted resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) { "doesNotExist" }
        end
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }

      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end
      end

      context 'with invalid resource' do
        let(:resource) { FactoryBot.create(:project, :invalid) }
        let!(:resource_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: resource) }

        it { expect(resource).to be_invalid }
        it { expect(resource).not_to be_is_deleted }

        it_behaves_like 'a removable resource' do
          let(:resource_counter) { resource_class.where(is_deleted: false) }

          it 'should be marked as deleted' do
            expect(resource).to be_persisted
            is_expected.to eq(204)
            resource.reload
            expect(resource.is_deleted?).to be_truthy
          end
        end
      end

      context 'with root file and folder' do
        let(:root_folder) { FactoryBot.create(:folder, :root, project: resource) }
        let(:root_file) { FactoryBot.create(:data_file, :root, project: resource) }

        it_behaves_like 'a removable resource' do
          let(:resource_counter) { resource_class.where(is_deleted: false) }
          it 'should enqueue a ChildPurgationJob' do
            expect {
              expect(root_folder.is_deleted?).to be_falsey
              expect(root_file.is_deleted?).to be_falsey
              is_expected.to eq(204)
            }.to have_enqueued_job(ChildPurgationJob)
          end
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 204 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
        end
      end
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end
  end
end
