require 'rails_helper'

describe DDS::V1::FolderAPI do
  include_context 'with authentication'

  let(:folder) { FactoryGirl.create(:folder) }
  let(:child_folder) { FactoryGirl.create(:child_folder) }
  let(:child_and_parent) { FactoryGirl.create(:child_and_parent) }
  let(:deleted_folder) { FactoryGirl.create(:folder, :deleted, project: project) }
  let(:folder_stub) { FactoryGirl.build(:folder) }
  let(:serialized_folder) { FolderSerializer.new(folder).to_json }
  let(:other_permission) { FactoryGirl.create(:project_permission, user: current_user) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_permission.project) }

  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { folder }
  let(:resource_id) { folder.id }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }

  let(:project) { resource.project }
  let(:project_id) { project.id}
  let(:child_folder_id) {child_folder.id}
  let(:child_and_parent_id) {child_and_parent.id}

  describe 'Folder collection' do
    let(:url) { "/api/v1/projects/#{project_id}/folders" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          deleted_folder,
          other_folder
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:project_id) {'notfoundid'}
        let(:resource_class) {'Project'}
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let(:project) { FactoryGirl.create(:project) }
      let!(:payload) {{
        parent: { id: folder_stub.parent_id },
        name: folder_stub.name
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'a validated resource' do
        let!(:payload) {{
          parent: { id: resource.parent_id },
          name: nil
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an identified resource' do
        let(:project_id) {'notfoundid'}
        let(:resource_class) {'Project'}
      end

      #TODO fix it to make this pass
      # it_behaves_like 'an identified resource' do
      #   let!(:payload) {{
      #     parent: { id: 'notfoundid' },
      #     name: folder_stub.name
      #   }}
      # end

      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 201 }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
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

        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 204 }
      end
      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Move a Project Folder to a New Parent' do
    let(:url) { "/api/v1/folders/#{resource_id}/move" }
    let(:new_parent) { FactoryGirl.create(:folder) }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        parent: { id: new_parent.id }
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'an audited endpoint'
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { new_parent }
      end
    end
  end

  describe 'Rename a Project Folder' do
    let(:url) { "/api/v1/folders/#{resource_id}/rename" }
    let(:new_name) { Faker::Team.name } #New name can be anything
    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        name: new_name
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

      it_behaves_like 'an audited endpoint'
      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Parent folder instance' do
    let(:url) { "/api/v1/folders/#{child_folder_id}/parent" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      let(:parent) { child_folder.parent }
      let(:resource) { parent }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:child_folder_id) {'notfoundid'}
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { child_folder }
      end
    end
  end

  describe 'Folder children collection' do
    let(:url) { "/api/v1/folders/#{child_and_parent_id}/children" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      #Adding resource to the list of factory-generated children allows testing for its inclusion
      let(:resource) { FactoryGirl.create(:folder, parent_id: child_and_parent.id) }
      #Add deleted folder to ensure it isn't included in listable result
      let(:deleted_folder) { FactoryGirl.create(:folder, :deleted, parent_id: child_and_parent.id) }
      let(:project) { child_and_parent.project }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { child_and_parent.children.count }
        it 'should not include deleted folders' do
          expect(deleted_folder).to be_persisted
          is_expected.to eq(200)
          expect(response.body).not_to include(resource_serializer.new(deleted_folder).to_json)
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:child_and_parent_id) {'notfoundid'}
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { child_and_parent }
      end
    end
  end
end
