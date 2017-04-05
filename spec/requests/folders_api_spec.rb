require 'rails_helper'

describe DDS::V1::FoldersAPI do
  include_context 'with authentication'
  let(:folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:parent) { folder.parent }
  let(:project) { folder.project }

  let(:child_file) { FactoryGirl.create(:data_file, parent: folder) }
  let(:folder_at_root) { FactoryGirl.create(:folder, :root, project: project) }
  let(:deleted_folder) { FactoryGirl.create(:folder, :deleted, project: project) }
  let(:folder_stub) { FactoryGirl.build(:folder, project: project) }
  let(:other_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user) }
  let(:other_project) { other_permission.project }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }

  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { folder }
  let(:resource_id) { resource.id }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }

  let(:project_id) { project.id}

  describe 'Folder collection' do
    let(:url) { "/api/v1/folders" }

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let!(:payload) {{
        parent: { kind: parent.kind, id: parent.id },
        name: folder_stub.name
      }}

      it_behaves_like 'a creatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          parent: { kind: parent.kind, id: parent.id },
          name: nil
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      context 'without parent in payload' do
        let(:payload) {{
          name: folder_stub.name
        }}
        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end

      context 'with project as parent' do
        let(:parent) { project }
        it_behaves_like 'an identified resource' do
          let!(:payload) {{
            parent: { kind: parent.kind, id: 'notfoundid' },
            name: folder_stub.name
          }}
          let(:resource_class) {'Project'}
        end

        it_behaves_like 'a logically deleted resource' do
          let(:deleted_resource) { project }
        end
      end

      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          parent: { kind: parent.kind, id: 'notfoundid' },
          name: folder_stub.name
        }}
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
      end

      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 201 }
        end
      end
    end

    describe 'GET' do
      subject { get(url, headers: headers) }

      it 'returns a method not allowed error' do
        is_expected.to eq 405
      end
    end
  end

  describe 'Folder instance' do
    let(:url) { "/api/v1/folders/#{resource_id}" }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'a logically deleted resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }
      include_context 'with job runner', ChildDeletionJob

      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end
      end

      context 'with invalid child file' do
        let!(:invalid_child_file) { FactoryGirl.create(:data_file, :invalid, parent: resource) }

        it { expect(invalid_child_file).to be_invalid }

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

      context 'with children' do
        let(:resource) { parent }
        let!(:child) { folder }
        let!(:file_child) { FactoryGirl.create(:data_file, parent: parent) }
        let!(:grand_child) { child_file }

        it_behaves_like 'a removable resource' do
          let(:resource_counter) { resource_class.base_class.where(is_deleted: false) }

          context 'with inline ActiveJob' do
            before do
              ActiveJob::Base.queue_adapter = :inline
            end

            it 'should be marked as deleted' do
              is_expected.to eq(204)
              expect(resource.reload).to be_truthy
              expect(resource.is_deleted?).to be_truthy
            end

            it 'should mark children as deleted' do
              is_expected.to eq(204)
              expect(folder.reload).to be_truthy
              expect(folder.is_deleted?).to be_truthy
              expect(file_child.reload).to be_truthy
              expect(file_child.is_deleted?).to be_truthy
              expect(child_file.reload).to be_truthy
              expect(child_file.is_deleted?).to be_truthy
            end
          end

          context 'with queued ActiveJob' do
            it 'should be marked as deleted' do
              is_expected.to eq(204)
              expect(resource.reload).to be_truthy
              expect(resource.is_deleted?).to be_truthy
            end

            it 'should create ChildDeletionJob entries for child folders and their files' do
              expect {
                is_expected.to eq(204)
              }.to have_enqueued_job(ChildDeletionJob)
            end
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

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Move folder' do
    let(:url) { "/api/v1/folders/#{resource_id}/move" }

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let!(:new_parent) { folder_at_root }
      let(:payload) {{
        parent: { kind: new_parent.kind, id: new_parent.id }
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint'
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'an identified resource' do
        let(:payload) {{
          parent: { kind: new_parent.kind, id: 'notfoundid' }
        }}
      end

      context 'with child as new parent' do
        let(:resource) { parent }
        let(:new_parent) { folder }
        it_behaves_like 'a validated resource'
      end

      context 'with different project as new parent' do
        let(:new_parent) { other_project }
        it_behaves_like 'a validated resource'
      end

      context 'with folder in different project as new parent' do
        let(:new_parent) { other_folder }
        it_behaves_like 'a validated resource'
      end

      context 'with project as parent' do
        let(:new_parent) { project }

        it_behaves_like 'an updatable resource'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an authorized resource'
        it_behaves_like 'an annotate_audits endpoint'
        it_behaves_like 'a software_agent accessible resource' do
          it_behaves_like 'an annotate_audits endpoint'
        end
        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end
        it_behaves_like 'an identified resource' do
          let(:payload) {{
            parent: { kind: new_parent.kind, id: 'notfoundid' }
          }}
          let(:resource_class) {'Project'}
        end
      end

      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { new_parent }
      end
    end
  end

  describe 'Rename folder' do
    let(:url) { "/api/v1/folders/#{resource_id}/rename" }
    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        name: folder_stub.name
      }}
      it_behaves_like 'an updatable resource'
      it_behaves_like 'a validated resource' do
        let(:payload) {{
          name: nil
        }}
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint'
      end
      it_behaves_like 'a logically deleted resource'
    end
  end
end
