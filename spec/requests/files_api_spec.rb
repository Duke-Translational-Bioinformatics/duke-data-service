require 'rails_helper'

describe DDS::V1::FilesAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:upload) { FactoryGirl.create(:upload, :completed, project: project, creator: current_user) }
  let(:folder) { FactoryGirl.create(:folder, project: project) }
  let(:file) { FactoryGirl.create(:data_file, project: project, upload: upload) }
  let(:invalid_file) { FactoryGirl.create(:data_file, :invalid, project: project, upload: upload) }
  let(:project_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }
  let(:parent) { folder }
  let(:other_permission) { FactoryGirl.create(:project_permission, user: current_user) }
  let(:other_project) { other_permission.project }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }
  let(:other_upload) { FactoryGirl.create(:upload, project: other_project, creator: current_user) }

  let(:incomplete_upload) { FactoryGirl.create(:upload, project: project, creator: current_user) }
  let(:error_upload) { FactoryGirl.create(:upload, :with_error, project: project, creator: current_user) }

  let(:resource_class) { DataFile }
  let(:resource_serializer) { DataFileSerializer }
  let!(:resource) { file }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }

  describe 'Files collection' do
    let(:url) { "/api/v1/files" }

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { 'POST' }
      let(:payload_parent) {{ kind: parent.kind, id: parent.id }}
      let(:payload_upload) {{ id: upload.id }}
      let!(:payload) {{
        parent: payload_parent,
        upload: payload_upload
      }}

      it_behaves_like 'a creatable resource' do
        it 'should set creator' do
          is_expected.to eq(expected_response_status)
          expect(new_object.creator_id).to eq(current_user.id)
        end
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      context 'with incomplete upload' do
        let(:payload_upload) {{ id: incomplete_upload.id }}
        it_behaves_like 'a validated resource'
      end

      context 'with an error upload' do
        let(:payload_upload) {{ id: error_upload.id }}
        it_behaves_like 'a validated resource'
      end

      it_behaves_like 'an identified resource' do
        let(:payload_parent) {{ kind: parent.kind, id: 'notfoundid' }}
        let(:resource_class) {'Folder'}
      end

      it_behaves_like 'an identified resource' do
        let(:payload_upload) {{ id: 'notfoundid' }}
        let(:resource_class) { 'Upload' }
      end

      it_behaves_like 'an identified resource' do
        let(:payload_upload) {{ id: other_upload.id }}
        let(:resource_class) { 'Upload' }
      end

      context 'without parent in payload' do
        let(:payload) {{
          upload: payload_upload
        }}
        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end

      context 'without upload in payload' do
        let(:payload) {{
          parent: payload_parent
        }}
        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end

      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 201 }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { parent }
      end

      context 'with project as parent' do
        let(:parent) { project }
        it_behaves_like 'an identified resource' do
          let(:payload_parent) {{ kind: parent.kind, id: 'notfoundid' }}
          let(:resource_class) {'Project'}
        end

        it_behaves_like 'a logically deleted resource' do
          let(:deleted_resource) { parent }
        end
      end
    end
  end

  describe 'File instance' do
    let(:url) { "/api/v1/files/#{resource_id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
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

      context 'with invalid resource' do
        let(:resource) { invalid_file }

        it { expect(resource).to be_invalid }

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
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint' do
        let(:expected_status) { 204 }
      end
      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Download a file' do
    let(:url) { "/api/v1/files/#{resource_id}/url" }
    let(:resource_serializer) { DataFileUrlSerializer }

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
  end

  describe 'Move file' do
    let(:url) { "/api/v1/files/#{resource_id}/move" }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:new_parent) { FactoryGirl.create(:folder, project: project) }
      let(:payload) {{
        parent: { kind: new_parent.kind, id: new_parent.id }
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint'
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { new_parent }
      end

      it_behaves_like 'an identified resource' do
        let(:payload) {{
          parent: { kind: new_parent.kind, id: 'notfoundid' }
        }}
        let(:resource_class) {new_parent.class}
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
        it_behaves_like 'an audited endpoint'
        it_behaves_like 'a logically deleted resource'
        it_behaves_like 'an identified resource' do
          let(:resource_id) {'notfoundid'}
        end

        it_behaves_like 'a logically deleted resource' do
          let(:deleted_resource) { new_parent }
        end

        it_behaves_like 'an identified resource' do
          let(:payload) {{
            parent: { kind: new_parent.kind, id: 'notfoundid' }
          }}
          let(:resource_class) {new_parent.class}
        end
      end
    end
  end

  describe 'Rename file' do
    let(:url) { "/api/v1/files/#{resource_id}/rename" }
    let(:new_name) { Faker::Team.name } #New name can be anything
    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        name: new_name
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an audited endpoint'
      it_behaves_like 'a logically deleted resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'a validated resource' do
        let(:new_name) { '' }
      end

      context 'without name in payload' do
        let(:payload) {{}}
        it 'returns a failed response' do
          is_expected.to eq(400)
          expect(response.status).to eq(400)
        end
      end
    end
  end
end
