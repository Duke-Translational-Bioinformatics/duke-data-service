require 'rails_helper'

describe DDS::V1::ProjectTransfersAPI do
  include_context 'with authentication'
  let(:project) { FactoryBot.create(:project) }
  let(:other_project) { FactoryBot.create(:project) }

  let(:project_transfer) { FactoryBot.create(:project_transfer, :with_to_users, project: project) }
  let(:to_user) { FactoryBot.create(:user) }
  let(:other_project_transfer) { FactoryBot.create(:project_transfer, :with_to_users) }
  let(:project_transfer_stub) { FactoryBot.build(:project_transfer, :with_to_users) }
  let(:project_transfer_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:pending_project_transfer) { FactoryBot.create(:project_transfer, :with_to_users, :pending) }
  let(:rejected_project_transfer) { FactoryBot.create(:project_transfer, :with_to_users, :rejected, project: project) }
  let!(:project_viewer) { FactoryBot.create(:auth_role, :project_viewer) }
  let!(:project_admin) { FactoryBot.create(:auth_role, :project_admin) }

  let(:resource_class) { ProjectTransfer }
  let(:resource_serializer) { ProjectTransferSerializer }
  let!(:resource) { project_transfer }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_transfer_permission }
  let(:resource_stub) { project_transfer_stub }

  describe 'Project Transfer Collection' do
    let(:url) { "/api/v1/projects/#{project_id}/transfers" }
    let(:project_id) { project.id }

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let(:payload) {{
        to_users: [
            {
            id: payload_to_user_id
            }
          ]
      }}
      let(:payload_to_user_id) { to_user.id }

      it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
      end
      it_behaves_like 'a creatable resource' do
        it 'should set status to pending' do
          is_expected.to eq(expected_response_status)
          expect(new_object.status).to eq('pending')
        end
        it 'should set project' do
          is_expected.to eq(expected_response_status)
          expect(new_object.project).to eq(project)
        end
        it 'from_user is set to current user' do
          is_expected.to eq(expected_response_status)
          expect(new_object.from_user).to eq(current_user)
        end
        it 'to_users should contain to_user' do
          is_expected.to eq(expected_response_status)
          expect(new_object.to_users).to contain_exactly(to_user)
        end
      end
      context 'with invalid project_id' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
        it_behaves_like 'an identified resource'
      end
      context 'where project_transfer is pending' do
        let(:project) { pending_project_transfer.project }
        it_behaves_like 'a validated resource'
      end
      context 'where to_user_id does not exist' do
        let(:payload_to_user_id) { "doesNotExist" }
        it_behaves_like 'a validated resource'
      end
      context 'where to_users array is empty' do
        let(:payload) {{ to_users: [] }}
        it_behaves_like 'a validated resource'
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }
      let(:project_transfer_from) { FactoryBot.create(:project_transfer, :with_to_users, from_user: current_user)}
      let(:project_transfer_to) { FactoryBot.create(:project_transfer, :with_to_users, to_user: current_user)}

      it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'where user has project_permission for project' do
        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            project_transfer
          ]}
          let!(:unexpected_resources) { [
            other_project_transfer,
            project_transfer_from,
            project_transfer_to
          ] }
        end
      end
      context 'where user is from_user' do
        let(:project_id) { project_transfer_from.project.id }
        it_behaves_like 'a listable resource' do
          let(:serializable_resource) { project_transfer_from }
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            project_transfer_from
          ]}
          let!(:unexpected_resources) { [
            other_project_transfer,
            project_transfer,
            project_transfer_to
          ] }
        end
      end
      context 'where user is to_user' do
        let(:project_id) { project_transfer_to.project.id }
        it_behaves_like 'a listable resource' do
          let(:serializable_resource) { project_transfer_to }
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            project_transfer_to
          ]}
          let!(:unexpected_resources) { [
            other_project_transfer,
            project_transfer,
            project_transfer_from
          ] }
        end
      end

      context 'with invalid project_id' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
        it_behaves_like 'an identified resource'
      end
    end
  end

  describe 'Project Transfer instance' do
    let(:url) { "/api/v1/project_transfers/#{resource_id}" }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end

    describe 'Reject project transfer' do
      let(:url) { "/api/v1/project_transfers/#{resource_id}/reject" }
      let(:resource) { FactoryBot.create(:project_transfer,
                                          :with_to_users,
                                          status: status,
                                          to_user: current_user) }
      let(:status) { :pending }
      let(:payload) {{}}

      describe 'PUT' do
        subject { put(url, params: payload.to_json, headers: headers) }
        let(:called_action) { 'PUT' }

        it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end
        it_behaves_like 'a software_agent accessible resource'
        it_behaves_like 'an updatable resource' do
          it 'sets rejected status to true' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource).to be_rejected
          end
        end
        context 'when current user is not to_user' do
          let(:resource) { FactoryBot.create(:project_transfer,
                                              :with_to_users,
                                              status: status) }
          it_behaves_like 'an authorized resource'
        end
        context 'with status_comment' do
          let(:payload) {{
            status_comment: Faker::Hacker.say_something_smart
          }}
          it_behaves_like 'an updatable resource' do
            it 'sets rejected status to true and saves status comment' do
              is_expected.to eq(200)
              expect(resource.reload).to be_truthy
              expect(resource.status_comment).to eq(payload[:status_comment])
            end
          end
        end
        context 'where project_transfer status is rejected' do
          let(:status) { :rejected }
          before do
            expect(resource).to be_persisted
          end
          it_behaves_like 'a validated resource'
        end
      end
    end

    describe 'Cancel project transfer' do
      let(:url) { "/api/v1/project_transfers/#{resource_id}/cancel" }
      let(:resource) { FactoryBot.create(:project_transfer,
                                          :with_to_users,
                                          status: status,
                                          project: project) }
      let(:status) { :pending }
      let(:payload) {{}}

      describe 'PUT' do
        subject { put(url, params: payload.to_json, headers: headers) }
        let(:called_action) { 'PUT' }

        it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end
        it_behaves_like 'a software_agent accessible resource'
        it_behaves_like 'an updatable resource' do
          it 'sets canceled status to true' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource).to be_canceled
          end
        end
        context 'when current user is not to_user' do
          let(:resource) { FactoryBot.create(:project_transfer,
                                              :with_to_users,
                                              status: status) }
          it_behaves_like 'an authorized resource'
        end
        context 'with status_comment' do
          let(:payload) {{
            status_comment: Faker::Hacker.say_something_smart
          }}
          it_behaves_like 'an updatable resource' do
            it 'sets canceled status to true and saves status comment' do
              is_expected.to eq(200)
              expect(resource.reload).to be_truthy
              expect(resource.status_comment).to eq(payload[:status_comment])
            end
          end
        end
        context 'where project_transfer status is canceled' do
          let(:status) { :canceled }
          before do
            expect(resource).to be_persisted
          end
          it_behaves_like 'a validated resource'
        end
      end
    end

    describe 'Accept project transfer' do
      let(:url) { "/api/v1/project_transfers/#{resource_id}/accept" }
      let(:resource) { FactoryBot.create(:project_transfer,
                                          :with_to_users,
                                          project: project,
                                          status: status,
                                          to_user: current_user) }
      let(:status) { :pending }
      let(:payload) {{}}

      describe 'PUT' do
        subject { put(url, params: payload.to_json, headers: headers) }
        let(:called_action) { 'PUT' }

        it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end
        it_behaves_like 'a software_agent accessible resource'
        it_behaves_like 'an updatable resource' do
          it 'sets accepted status to true' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource).to be_accepted
          end
        end
        context 'when current user is not to_user' do
          let(:resource) { FactoryBot.create(:project_transfer,
                                              :with_to_users,
                                              status: status) }
          it_behaves_like 'an authorized resource'
        end
        context 'with status_comment' do
          let(:payload) {{
            status_comment: Faker::Hacker.say_something_smart
          }}
          it_behaves_like 'an updatable resource' do
            it 'sets accepted status to true and saves status comment' do
              is_expected.to eq(200)
              expect(resource.reload).to be_truthy
              expect(resource.status_comment).to eq(payload[:status_comment])
            end
          end
        end
        context 'where project_transfer status is not processing' do
          let(:status) { :accepted }
          before do
            expect(resource).to be_persisted
          end
          it_behaves_like 'a validated resource'
          it 'should retain current permissions' do
            expect(resource.project.project_permissions).not_to be_empty
            expect { is_expected.to eq(400) }.not_to change{ ProjectPermission.all.collect(&:attributes) }
          end
        end

        context 'when project has project_permissions' do
          let(:from_user_permission) { FactoryBot.create(:project_permission, :project_admin, user: resource.from_user, project: project) }
          let(:another_permission) { FactoryBot.create(:project_permission, project: project) }
          let(:different_permission) { FactoryBot.create(:project_permission) }
          before do
            expect(resource).to be_persisted
          end

          it 'should remove the from_user project_permission' do
            expect(from_user_permission).to be_persisted
            expect(ProjectPermission.where(project: project).all).to include(from_user_permission)
            is_expected.to eq(200)
            expect(ProjectPermission.where(project: project).all).not_to include(from_user_permission)
          end
          it 'should remove another_permission' do
            expect(another_permission).to be_persisted
            expect(ProjectPermission.where(project: project).all).to include(another_permission)
            is_expected.to eq(200)
            expect(ProjectPermission.where(project: project).all).not_to include(another_permission)
          end
          it 'should not remove a different projects permissions' do
            expect(different_permission).to be_persisted
            is_expected.to eq(200)
            expect{different_permission.reload}.not_to raise_error
          end
          it 'should grant project_viewer permission to from_user' do
            expect {
              is_expected.to eq(200)
            }.to change{ProjectPermission.where(project: project, user: resource.from_user, auth_role: project_viewer).count}.by(1)
          end
          it 'should grant project_admin permission to to_users' do
            expect {
              is_expected.to eq(200)
            }.to change{ProjectPermission.where(project: project, user: resource.to_users.unscope(:order), auth_role: project_admin).count}.by(1)
          end
        end
      end
    end
  end

  describe 'View all project transfers' do
    let(:url) { "/api/v1/project_transfers" }

    describe 'GET' do
      let(:payload) {nil}
      subject { get(url, params: payload, headers: headers) }
      let(:project_transfer_from) { FactoryBot.create(:project_transfer, :with_to_users, from_user: current_user)}
      let(:project_transfer_to) { FactoryBot.create(:project_transfer, :with_to_users, to_user: current_user)}

      it_behaves_like 'a feature toggled resource', env_key: 'SKIP_PROJECT_TRANSFERS'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a listable resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'when status query is not set' do
        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            project_transfer,
            project_transfer_from,
            project_transfer_to,
            rejected_project_transfer
          ]}
          let!(:unexpected_resources) { [
            other_project_transfer
          ] }
        end
      end

      context 'when status query is set' do
        let!(:payload) {{status: rejected_project_transfer.status}}
        it_behaves_like 'a listable resource' do
          let(:serializable_resource) { rejected_project_transfer }
          let(:expected_list_length) { expected_resources.length }
          let!(:expected_resources) { [
            rejected_project_transfer
          ]}
          let!(:unexpected_resources) { [
            other_project_transfer,
            project_transfer,
            project_transfer_from,
            project_transfer_to
          ] }
        end
      end

      context 'when status type does not exist' do
        let!(:payload) {{status: 'notexists'}}
        it 'should return 404 with error' do
          is_expected.to eq(404)
          expect(response.body).to be
          expect(response.body).not_to eq('null')
          response_json = JSON.parse(response.body)
          expect(response_json).to have_key('error')
          expect(response_json['error']).to eq('404')
          expect(response_json).to have_key('code')
          expect(response_json['code']).to eq('not_provided')
          expect(response_json).to have_key('reason')
          expect(response_json['reason']).to eq("Unknown Status")
          expect(response_json).to have_key('suggestion')
          expect(response_json['suggestion']).to eq("Status should be one of the following: #{ProjectTransfer.statuses.keys}")
        end
      end
    end
  end
end
