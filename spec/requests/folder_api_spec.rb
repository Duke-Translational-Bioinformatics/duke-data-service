require 'rails_helper'

describe DDS::V1::FolderAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:folder) { FactoryGirl.create(:folder) }
  let(:child_folder) { FactoryGirl.create(:child_folder) }
  let(:child_and_parent) { FactoryGirl.create(:child_and_parent) }
  let(:deleted_folder) { FactoryGirl.create(:folder, :deleted) }
  let(:folder_stub) { FactoryGirl.build(:folder) }
  let(:serialized_folder) { FolderSerializer.new(folder).to_json }

  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { folder }

  describe 'Folder collection' do
    let(:url) { "/api/v1/projects/#{project.id}/folders" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      let(:project) { resource.project }

      it_behaves_like 'a listable resource' do
        it 'should not include deleted folders' do
          is_expected.to eq(200)
          expect(response.body).not_to include(resource_serializer.new(deleted_folder).to_json)
        end
      end

      it_behaves_like 'an authenticated resource'
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let!(:payload) {{
        parent: { id: folder_stub.parent_id },
        name: folder_stub.name
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'an authenticated resource'

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
    end
  end

  describe 'Folder instance' do
    let(:url) { "/api/v1/folders/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
    end

    describe 'DELETE' do
      subject { delete(url, nil, headers) }
      it_behaves_like 'a removable resource' do
        let(:resource_counter) { resource_class.where(is_deleted: false) }

        it 'should be marked as deleted' do
          expect(resource).to be_persisted
          is_expected.to eq(204)
          resource.reload
          expect(resource.is_deleted?).to be_truthy
        end
      end

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Move a Project Folder to a New Parent' do
    let(:url) { "/api/v1/folders/#{resource.id}/move" }
    let(:new_parent) { FactoryGirl.create(:folder) }
    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        parent: { id: new_parent.id }
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Rename a Project Folder' do
    let(:url) { "/api/v1/folders/#{resource.id}/rename" }
    let(:new_name) { Faker::Team.name } #New name can be anything
    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
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
    end
  end

  describe 'Parent folder instance' do
    let(:url) { "/api/v1/folders/#{child_folder.id}/parent" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      let(:parent) { child_folder.parent }
      let(:resource) { parent }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
    end
  end

  describe 'Folder children collection' do
    let(:url) { "/api/v1/folders/#{child_and_parent.id}/children" }

    describe 'GET' do
      subject { get(url, nil, headers) }
      #Adding resource to the list of factory-generated children allows testing for its inclusion
      let(:resource) { FactoryGirl.create(:folder, parent_id: child_and_parent.id) }
      #Add deleted folder to ensure it isn't included in listable result
      let(:deleted_foler) { FactoryGirl.create(:folder, :deleted, parent_id: child_and_parent.id) }
      it_behaves_like 'a listable resource' do
        it 'should not include deleted folders' do
          is_expected.to eq(200)
          expect(response.body).not_to include(resource_serializer.new(deleted_folder).to_json)
        end
      end

      it_behaves_like 'an authenticated resource'
    end
  end
end
