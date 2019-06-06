require 'rails_helper'

describe DDS::V1::FilesAPI do
  include_context 'with authentication'
  include_context 'mock all Uploads StorageProvider'
  
  let(:project) { FactoryBot.create(:project) }
  let(:upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, project: project, creator: current_user, is_consistent: true) }
  let(:folder) { FactoryBot.create(:folder, project: project) }
  let(:file) { FactoryBot.create(:data_file, project: project, upload: upload) }
  let(:invalid_file) { FactoryBot.create(:data_file, :invalid, project: project, upload: upload) }
  let(:deleted_file) { FactoryBot.create(:data_file, :deleted, project: project) }
  let(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:parent) { folder }
  let(:other_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user) }
  let(:other_project) { other_permission.project }
  let(:other_folder) { FactoryBot.create(:folder, project: other_project) }
  let(:other_file) { FactoryBot.create(:data_file, :root, project: other_project) }
  let(:other_upload) { FactoryBot.create(:upload, project: other_project, creator: current_user) }

  let(:completed_upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, project: project, creator: current_user) }
  let(:incomplete_upload) { FactoryBot.create(:upload, project: project, creator: current_user) }
  let(:error_upload) { FactoryBot.create(:upload, :with_error, project: project, creator: current_user) }

  let(:resource_class) { DataFile }
  let(:resource_serializer) { DataFileSerializer }
  let!(:resource) { file }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { FactoryBot.build(:data_file, project: project, upload: upload) }

  describe 'Project Files collection' do
    let(:url) { "/api/v1/projects/#{project_id}/files" }
    let(:project_id) { project.id }
    let(:payload) {{}}
    let(:resource_serializer) { DataFileSummarySerializer }

    #List files for a project
    it_behaves_like 'a GET request' do
      it_behaves_like 'a listable resource' do
        before do
          allow_any_instance_of(DataFile).to receive(:url).and_return("mocked_temporary_url")
        end
        let(:unexpected_resources) { [
          other_file,
          deleted_file
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end

      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { project.data_files.count }
        let(:extras) { FactoryBot.create_list(:data_file, 5, project: project) }

        context 'with 1 per_page' do
          let(:pagination_parameters) { { page: 1, per_page: 1 } }
          let(:newer_file) { FactoryBot.create(:data_file, project: project) }

          it 'contains only the most recently updated file' do
            expect(resource).to be_persisted
            expect(newer_file).to be_persisted
            resource.touch
            is_expected.to eq(expected_response_status)
            expect(response.body).to include(resource_serializer.new(resource).to_json)
            expect(response.body).not_to include(resource_serializer.new(newer_file).to_json)
          end
        end
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'a software_agent accessible resource'

      context 'setting Project-Files-Query header' do
        before(:each) do
          allow(Rails.logger).to receive(:info).and_call_original
        end

        context 'unset' do
          it 'logs the default' do
            expect(Rails.logger).to receive(:info).with("Project-Files-Query = plain")
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:includes)
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:references)
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:preload)
            is_expected.to eq 200
          end

          it 'logs PROJECT_FILES_QUERY_DEFAULT env' do
            ENV['PROJECT_FILES_QUERY_DEFAULT'] = 'preload_only'
            expect(Rails.logger).to receive(:info).with("Project-Files-Query = preload_only")
            is_expected.to eq 200
            ENV.delete('PROJECT_FILES_QUERY_DEFAULT')
          end
        end

        context 'set to preload_only' do
          it 'logs proload_only' do
            headers['Project-Files-Query']='preload_only'
            expect(Rails.logger).to receive(:info).with("Project-Files-Query = preload_only")
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:includes).with(file_versions: [upload: [:fingerprints, :storage_provider]]).and_call_original
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:references)
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:preload)
            is_expected.to eq 200
          end
        end

        context 'set to join_only' do
          it 'logs proload_only' do
            headers['Project-Files-Query']='join_only'
            expect(Rails.logger).to receive(:info).with("Project-Files-Query = join_only")
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:includes).with(file_versions: [upload: [:fingerprints, :storage_provider]]).and_call_original
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:references).with(:file_versions).and_call_original
            expect_any_instance_of(ActiveRecord::AssociationRelation).not_to receive(:preload)
            is_expected.to eq 200
          end
        end

        context 'set to join_and_preload' do
          it 'logs proload_only' do
            headers['Project-Files-Query']='join_and_preload'
            expect(Rails.logger).to receive(:info).with("Project-Files-Query = join_and_preload")
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:includes).with(:file_versions).and_call_original
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:references).with(:file_versions).and_call_original
            expect_any_instance_of(ActiveRecord::AssociationRelation).to receive(:preload).with(file_versions: [upload: [:fingerprints, :storage_provider]]).and_call_original
            is_expected.to eq 200
          end
        end
      end
    end
  end

  describe 'Files collection' do
    let(:url) { "/api/v1/files" }

    describe 'POST' do
      subject { post(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'POST' }
      let(:payload_parent) {{ kind: parent.kind, id: parent.id }}
      let(:payload_upload) {{ id: upload.id }}
      let!(:payload) {{
        parent: payload_parent,
        upload: payload_upload,
        label: resource_stub.label
      }}

      it_behaves_like 'a creatable resource' do
        it 'should set label' do
          is_expected.to eq(expected_response_status)
          expect(new_object.label).to eq(payload[:label])
        end
        it 'creates a file_version' do
          expect {
            is_expected.to eq(201)
          }.to change{FileVersion.count}.by(1)
        end
      end
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }

        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 201 }
          let(:expected_auditable_type) { FileVersion }
        end
      end

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

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
        let(:expected_auditable_type) { FileVersion }
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
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let(:payload_upload) {{ id: completed_upload.id }}
      let(:payload) {{
        upload: payload_upload,
        label: resource_stub.label
      }}

      it_behaves_like 'an updatable resource' do
        it 'creates a file_version' do
          expect {
            is_expected.to eq(200)
          }.to change{resource.file_versions.count}.by(1)
        end
        it_behaves_like 'an annotate_audits endpoint'
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_auditable_type) { FileVersion }
        end

        context 'with only upload in payload' do
          let(:payload) {{
            upload: payload_upload
          }}
          it_behaves_like 'an annotate_audits endpoint'
          it_behaves_like 'an annotate_audits endpoint' do
            let(:expected_auditable_type) { FileVersion }
          end
        end

        it_behaves_like 'a software_agent accessible resource' do
          it 'creates a file_version' do
              expect {
                is_expected.to eq(200)
              }.to change{resource.file_versions.count}.by(1)
          end

          it_behaves_like 'an annotate_audits endpoint'
          it_behaves_like 'an annotate_audits endpoint' do
            let(:expected_auditable_type) { FileVersion }
          end
        end
      end

      context 'without upload in payload' do
        let(:payload) {{
          label: resource_stub.label
        }}
        it_behaves_like 'an updatable resource' do
          it 'does not create a file_version' do
            expect {
              is_expected.to eq(200)
            }.to change{resource.file_versions.count}.by(0)
          end
          it 'sets data_file label' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource.label).to eq(payload[:label])
          end
          it 'sets current_file_version label' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource.current_file_version.label).to eq(payload[:label])
          end
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'an authorized resource'
        it_behaves_like 'an annotate_audits endpoint'
        it_behaves_like 'a software_agent accessible resource' do
          it 'does not create a file_version' do
              expect {
                is_expected.to eq(200)
              }.to change{resource.file_versions.count}.by(0)
          end

          it_behaves_like 'an annotate_audits endpoint'
        end
      end

      context 'with current_file_version upload in payload' do
        let(:payload_upload) {{ id: resource.current_file_version.upload.id }}

        it_behaves_like 'an updatable resource' do
          it 'sets data_file label' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource.label).to eq(payload[:label])
          end
          it 'sets current_file_version label' do
            is_expected.to eq(200)
            expect(resource.reload).to be_truthy
            expect(resource.current_file_version.label).to eq(payload[:label])
          end
          it 'does not create a file_version' do
            expect {
              is_expected.to eq(200)
            }.to change{resource.file_versions.count}.by(0)
          end
        end
      end

      context 'with incomplete upload' do
        let(:payload_upload) {{ id: incomplete_upload.id }}
        it_behaves_like 'a validated resource'
      end

      context 'with an error upload' do
        let(:payload_upload) {{ id: error_upload.id }}
        it_behaves_like 'a validated resource'
      end

      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'an identified resource' do
        let(:payload) {{
          upload: { id: 'notfoundid' }
        }}
        let(:resource_class) { Upload }
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }

      context 'root data_file' do
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

      context 'folder child file' do
        let(:resource) { FactoryBot.create(:data_file, project: project, upload: upload, parent: folder) }

        it_behaves_like 'a removable resource' do
          let(:resource_counter) { resource_class.where(is_deleted: false) }

          it 'should be marked as deleted and moved to the root of the project' do
            expect(resource).to be_persisted
            expect(resource.parent).not_to be_nil
            expect(resource.deleted_from_parent).to be_nil
            original_parent = resource.parent

            is_expected.to eq(204)

            resource.reload
            expect(resource.is_deleted?).to be_truthy
            expect(resource.parent).to be_nil
            expect(resource.deleted_from_parent).not_to be_nil
            expect(resource.deleted_from_parent).to eq original_parent
          end
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

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) {204}
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 204 }
        end
      end
      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Download a file' do
    let(:url) { "/api/v1/files/#{resource_id}/url" }
    let(:resource_serializer) { DataFileUrlSerializer }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an eventually consistent resource', :upload
      it_behaves_like 'an eventually consistent upload integrity exception', :upload

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'a logically deleted resource'
    end
  end

  describe 'Move file' do
    let(:url) { "/api/v1/files/#{resource_id}/move" }

    describe 'PUT' do
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let!(:new_parent) { FactoryBot.create(:folder, project: project) }
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
        it_behaves_like 'an annotate_audits endpoint'
        it_behaves_like 'a software_agent accessible resource' do
          it_behaves_like 'an annotate_audits endpoint'
        end
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
      subject { put(url, params: payload.to_json, headers: headers) }
      let(:called_action) { 'PUT' }
      let!(:payload) {{
        name: new_name
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint'
      end
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
