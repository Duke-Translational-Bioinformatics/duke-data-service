require 'rails_helper'

describe DDS::V1::FileAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:upload) { FactoryGirl.create(:upload, project_id: project.id) }
  let(:folder) { FactoryGirl.create(:folder, project_id: project.id) }
  let(:file) { FactoryGirl.create(:data_file, project_id: project.id, upload_id: upload.id) }
  let(:project_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }

  let(:resource_class) { DataFile }
  let(:resource_serializer) { DataFileSerializer }
  let!(:resource) { file }
  let!(:resource_permission) { project_permission }

  describe 'Files collection' do
    let(:url) { "/api/v1/projects/#{project.id}/files" }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let!(:payload) {{
        parent: { id: folder.id },
        upload: { id: upload.id }
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_project_id/files" }
        let(:resource_class) {'Project'}
      end

      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          parent: { id: 'notfoundid' },
          upload: { id: upload.id }
        }}
        let(:resource_class) {'Folder'}
      end

      it_behaves_like 'an identified resource' do
        let!(:payload) {{
          upload: { id: 'notfoundid' },
          parent: { id: folder.id }
        }}
        let(:resource_class) { 'Upload' }
      end

      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 201 }
      end
    end
  end

  describe 'File instance' do
    let(:url) { "/api/v1/files/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/files/notexists_file_id" }
      end
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

        it_behaves_like 'an identified resource' do
          let(:url) { "/api/v1/files/notexists_file_id" }
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 204 }
      end
    end
  end

  describe 'Download a file' do
    let(:url) { "/api/v1/files/#{resource.id}/download" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it 'permenantly redirects to a temporary get url for the upload' do
        is_expected.to eq(301)
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/files/notexists_file_id/download" }
      end
    end
  end

  describe 'Move a File metadata Object to a New Parent' do
    let(:url) { "/api/v1/files/#{resource.id}/move" }
    let(:new_parent) { FactoryGirl.create(:folder, project_id: project.id) }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        parent: { id: new_parent.id }
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/files/notexists_file_id/move" }
      end
      it_behaves_like 'an audited endpoint'
    end
  end

  describe 'Rename a File metadata Object' do
    let(:url) { "/api/v1/files/#{resource.id}/rename" }
    let(:new_name) { Faker::Team.name } #New name can be anything
    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        name: new_name
      }}
      it_behaves_like 'an updatable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/files/notexists_file_id/rename" }
      end
      it_behaves_like 'an audited endpoint'
    end
  end
end
