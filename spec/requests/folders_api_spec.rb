require 'rails_helper'

describe DDS::V1::FoldersAPI do
  include_context 'with authentication'

  let(:folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:parent) { folder.parent }
  let(:project) { folder.project }
  let(:folder_at_root) { FactoryGirl.create(:folder, :root, project: project) }
  let(:deleted_folder) { FactoryGirl.create(:folder, :deleted, project: project) }
  let(:folder_stub) { FactoryGirl.build(:folder, project: project) }
  let(:other_permission) { FactoryGirl.create(:project_permission, user: current_user) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_permission.project) }

  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { folder }
  let(:resource_id) { folder.id }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }

  let(:project_id) { project.id}

  describe 'Folder collection' do
    let(:url) { "/api/v1/folders" }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
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

      it_behaves_like 'an audited endpoint' do
        let(:resource_class) { Container }
        let(:expected_status) { 201 }
      end
    end

    describe 'GET' do
      subject { get(url, nil, headers) }

      it 'returns a method not allowed error' do
        is_expected.to eq 405
      end
    end
  end

  describe 'Folder instance' do
    let(:url) { "/api/v1/folders/#{resource_id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'a logically deleted resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      let(:called_action) { 'DELETE' }

      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end

        it_behaves_like 'a validated resource' do
          let(:resource_id) { parent.id }
          it 'should not persist changes' do
            expect(resource).to be_persisted
            expect {
              is_expected.to eq(400)
            }.not_to change{resource_class.count}
          end
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:resource_class) { Container }
        let(:expected_status) { 204 }
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
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:new_parent) { folder_at_root }
      let(:payload) {{
        parent: { kind: new_parent.kind, id: new_parent.id }
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:resource_class) { Container }
      end
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
      it_behaves_like 'an identified resource' do
        let(:payload) {{
          parent: { kind: new_parent.kind, id: 'notfoundid' }
        }}
      end

      context 'with project as parent' do
        let(:new_parent) { project }

        it_behaves_like 'an updatable resource'
        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an authorized resource'
        it_behaves_like 'an audited endpoint' do
          let(:resource_class) { Container }
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
      subject { put(url, payload.to_json, headers) }
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
      it_behaves_like 'an audited endpoint' do
        let(:resource_class) { Container }
      end
      it_behaves_like 'a logically deleted resource'
    end
  end
end
