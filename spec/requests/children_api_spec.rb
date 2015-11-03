require 'rails_helper'

describe DDS::V1::ChildrenAPI do
  include_context 'with authentication'

  let(:folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:parent) { folder.parent }
  let(:project) { folder.project }
  let(:file) { FactoryGirl.create(:data_file, parent: parent) }

  let(:root_folder) { FactoryGirl.create(:folder, :root, project: project) }
  let(:root_file) { FactoryGirl.create(:data_file, :root, project: project) }
  let(:root_deleted_folder) { FactoryGirl.create(:folder, :deleted, :root, project: project) }

  let(:other_permission) { FactoryGirl.create(:project_permission, user: current_user) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_permission.project) }
  let(:deleted_folder) { FactoryGirl.create(:folder, :deleted, project: project, parent: parent) }

  let(:file_class) { DataFile }
  let(:file_serializer) { DataFileSerializer }

  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { folder }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }
  let(:parent_id) { parent.id }

  describe 'Folder children collection' do
    let(:url) { "/api/v1/folders/#{parent_id}/children" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { 1 }
        let!(:unexpected_resources) { [
          deleted_folder,
          other_folder
        ] }
      end

      context 'with file child' do
        let(:resource_class) { file_class }
        let(:resource_serializer) { file_serializer }
        let!(:resource) { file }

        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { 2 }
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:parent_id) { 'notfoundid' }
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { parent }
      end
    end
  end

  describe 'Project children collection' do
    let(:resource) { root_folder }
    let(:parent_id) { project.id }
    let(:parent) { project }
    let(:url) { "/api/v1/projects/#{parent_id}/children" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { 2 }
        let(:unexpected_resources) { [
          root_deleted_folder,
          other_folder
        ] }
      end

      context 'with file child' do
        let(:resource_class) { file_class }
        let(:resource_serializer) { file_serializer }
        let!(:resource) { root_file }
        let(:parent) { folder.project }
        it_behaves_like 'a listable resource' do
          let(:expected_list_length) { 2 }
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:parent_id) { 'notfoundid' }
        let(:resource_class) { Project }
      end
      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
    end
  end
end
