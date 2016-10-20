require 'rails_helper'

describe DDS::V1::ProjectTransfersAPI do
  include_context 'with authentication'
  let(:project) { FactoryGirl.create(:project) }
  let(:other_project) { FactoryGirl.create(:project) }

  let(:project_transfer) { FactoryGirl.create(:project_transfer, :with_to_users, project: project) }
  let(:to_user) { FactoryGirl.create(:user) }
  let(:other_project_transfer) { FactoryGirl.create(:project_transfer, :with_to_users) }
  let(:project_transfer_stub) { FactoryGirl.build(:project_transfer, :with_to_users) }
  let(:project_transfer_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:pending_project_transfer) { FactoryGirl.create(:project_transfer, :with_to_users, :pending) }

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
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let(:payload) {{
        to_users: [
            {
            id: payload_to_user_id
            }
          ]
      }}
      let(:payload_to_user_id) { to_user.id }

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
      subject { get(url, nil, headers) }
      let(:project_transfer_from) { FactoryGirl.create(:project_transfer, :with_to_users, from_user: current_user)}
      let(:project_transfer_to) { FactoryGirl.create(:project_transfer, :with_to_users, to_user: current_user)}

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
end
