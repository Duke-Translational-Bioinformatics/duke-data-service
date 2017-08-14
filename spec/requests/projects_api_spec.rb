require 'rails_helper'

describe DDS::V1::ProjectsAPI do
  include_context 'with authentication'
  let(:project_admin_role) { FactoryGirl.create(:auth_role, :project_admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:deleted_project) { FactoryGirl.create(:project, :deleted) }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:project_stub) { FactoryGirl.build(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }

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

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { Project.all.count }
        let(:extras) { FactoryGirl.create_list(:project_permission, 5, :project_admin, user: current_user) }
      end
    end

    describe 'POST' do
      # subject { post(url, params: payload.to_json, headers: headers) }
      # let(:called_action) { "POST" }
      let(:payload) {{
        name: resource.name,
        description: resource.description
      }}
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
        description: project_stub.description
      }}

      it_behaves_like 'a PUT request' do
        it_behaves_like 'an updatable resource'

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
        let(:resource) { FactoryGirl.create(:project, :invalid) }
        let!(:resource_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: resource) }

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
        let(:root_folder) { FactoryGirl.create(:folder, :root, project: resource) }
        let(:root_file) { FactoryGirl.create(:data_file, :root, project: resource) }

        it_behaves_like 'a removable resource' do
          let(:resource_counter) { resource_class.where(is_deleted: false) }
          let!(:storage_provider) { FactoryGirl.create(:storage_provider) }

          context 'with inline ActiveJob' do
            before do
              ActiveJob::Base.queue_adapter = :inline
              allow_any_instance_of(StorageProvider).to receive(:put_container).and_return(true)
            end

            it {
              expect(root_folder.is_deleted?).to be_falsey
              expect(root_file.is_deleted?).to be_falsey
              is_expected.to eq(204)
              expect(root_folder.reload).to be_truthy
              expect(root_folder.is_deleted?).to be_truthy
              expect(root_file.reload).to be_truthy
              expect(root_file.is_deleted?).to be_truthy
            }
          end

          context 'with queued ActiveJob' do
            it {
              expect {
                expect(root_folder.is_deleted?).to be_falsey
                expect(root_file.is_deleted?).to be_falsey
                is_expected.to eq(204)
              }.to have_enqueued_job(ChildDeletionJob)
            }
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
