require 'rails_helper'

describe DDS::V1::TrashbinAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:upload) { FactoryGirl.create(:upload, :completed, :with_fingerprint, project: project, creator: current_user, is_consistent: true) }
  let(:parent_folder) { FactoryGirl.create(:folder, project: project) }
  let(:trashed_resource) { FactoryGirl.create(:data_file, :deleted, project: project, upload: upload) }
  let(:untrashed_resource) { FactoryGirl.create(:data_file, project: project, upload: upload) }
  let(:purged_resource) { FactoryGirl.create(:data_file, :purged, project: project, upload: upload) }
  let(:project_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }
  let!(:resource_permission) { project_permission }

  describe 'GET /trashbin/{object_kind}/{object_id}' do
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}" }
    let(:resource) { trashed_resource }
    let(:resource_class) { DataFile }
    let(:resource_serializer) { DataFileSerializer }
    let(:resource_id) { trashed_resource.id }
    let(:resource_kind) { trashed_resource.kind }
    let(:payload) {{}}

    it_behaves_like 'a GET request' do
      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end

      it_behaves_like 'an identified resource' do
        let(:resource_id) { untrashed_resource.id }
      end

      it_behaves_like 'an identified resource' do
        let(:resource_id) { purged_resource.id }
      end

      it_behaves_like 'a kinded resource' do
        let(:resource_kind) { 'invalid-kind' }
      end

      it_behaves_like 'a software_agent accessible resource'
    end
  end

  describe 'PUT /trashbin/{object_kind}/{object_id}/restore' do
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}/restore" }
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:called_action) { 'PUT' }
    let(:parent_kind) { parent_folder.kind }
    let(:parent_id) { parent_folder.id }
    let(:resource) { trashed_resource }
    let(:resource_class) { DataFile }
    let(:resource_serializer) { DataFileSerializer }
    let(:resource_kind) { trashed_resource.kind }
    let(:resource_id) { trashed_resource.id }

    let(:payload) {{
      parent: {
        kind: parent_kind,
        id: parent_id
      }
    }}

    it_behaves_like 'an identified resource' do
      let(:resource_id) { "doesNotExist" }
    end

    it_behaves_like 'an identified resource' do
      let(:resource_id) { untrashed_resource.id }
    end

    it_behaves_like 'an identified resource' do
      let(:parent_id) { "doesNotExist" }
      let(:resource_class) { Folder }
    end

    it_behaves_like 'a client error' do
      let(:expected_response) { 404 }
      let(:expected_reason) { "dds-folder #{parent_folder.id} is deleted, and cannot restore children." }
      let(:expected_suggestion) { "Restore #{parent_folder.kind} #{parent_folder.id}." }
      before do
        parent_folder.update_columns(is_deleted: true)
      end
    end

    it_behaves_like 'a kinded resource' do
      let(:resource_kind) { 'invalid-kind' }
    end

    it_behaves_like 'a kinded resource' do
      let(:parent_kind) { 'invalid-kind' }
      let(:resource_kind) { 'invalid-kind' }
    end

    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'
    it_behaves_like 'an annotate_audits endpoint' do
      let(:expected_audits) { 3 }
    end

    it_behaves_like 'an updatable resource' do
      it 'restores the object to the requested parent' do
        is_expected.to eq(expected_response_status)
        trashed_resource.reload
        expect(trashed_resource.is_deleted).to be_falsey
        expect(trashed_resource.parent.id).to eq(parent_id)
      end

      it_behaves_like 'a software_agent accessible resource' do
        it 'restores the object to the requested parent' do
          is_expected.to eq(expected_response_status)
          trashed_resource.reload
          expect(trashed_resource.is_deleted).to be_falsey
          expect(trashed_resource.parent.id).to eq(parent_id)
        end

        it_behaves_like 'an annotate_audits endpoint' do
            let(:expected_audits) { 2 }
        end
      end
    end

    context 'file_version' do
      context 'containing file not deleted' do
        let(:file_version) {
          fv = untrashed_resource.file_versions.first
          fv.update_columns(is_deleted: true)
          fv.reload
          fv
        }
        let(:resource) { file_version }
        let(:resource_id) { file_version.id }
        let(:resource_kind) { file_version.kind }
        let(:resource_class) { FileVersion }
        let(:resource_serializer) { FileVersionSerializer }
        let(:payload) {{}}
        it_behaves_like 'an updatable resource' do
          it 'restores the object' do
            expect(file_version.is_deleted).to be_truthy
            expect(file_version.data_file.is_deleted).to be_falsey
            is_expected.to eq(expected_response_status)
            file_version.reload
            expect(file_version.is_deleted).to be_falsey
          end
        end
      end

      context 'containing data_file deleted' do
        let(:file_version) {
          fv = trashed_resource.file_versions.first
          fv.update_columns(is_deleted: true)
          fv
        }
        let(:resource_kind) { file_version.kind }
        let(:resource_id) { file_version.id }
        let(:payload) {{}}

        it_behaves_like 'a client error' do
          let(:expected_response) { 404 }
          let(:expected_reason) { "#{trashed_resource.kind} #{trashed_resource.id} is deleted, and cannot restore its versions." }
          let(:expected_suggestion) { "Restore #{file_version.data_file.kind} #{file_version.data_file_id}." }
        end
      end
    end

    context 'object is not Restorable' do
      let(:resource) { project }
      let(:resource_id) { project.id }
      let(:resource_kind) { project.kind }
      let(:resource_class) { Project }

      before do
        resource.update_columns(is_deleted: true)
      end
      it_behaves_like 'a client error' do
        let(:expected_response) { 404 }
        let(:expected_reason) { "#{project.kind} Not Restorable" }
        let(:expected_suggestion) { "#{project.kind} is not Restorable" }
      end
    end

    context 'already purged object' do
      let(:resource) { purged_resource }
      let(:resource_id) { purged_resource.id }
      let(:resource_kind) { purged_resource.kind }
      let(:resource_class) { purged_resource.class }

      it_behaves_like 'a viewable resource'
    end
  end

  describe 'PUT /trashbin/{object_kind}/{object_id}/purge' do
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}/purge" }
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:called_action) { 'PUT' }
    let(:trashed_file_version) {
      fv = trashed_resource.file_versions.first
      fv.update_columns(is_deleted: true)
      fv
    }
    let(:resource) { trashed_resource }
    let(:resource_kind) { trashed_resource.kind }
    let(:resource_id) { trashed_resource.id }
    let(:resource_class) { trashed_resource.class }
    let(:payload) {{}}

    it_behaves_like 'an identified resource' do
      let(:resource_id) { "doesNotExist" }
    end

    it_behaves_like 'an identified resource' do
      let(:resource_id) { untrashed_resource.id }
    end

    it_behaves_like 'a client error' do
      let(:resource_kind) { trashed_file_version.kind }
      let(:resource_id) { trashed_file_version.id }
      let(:expected_response) { 404 }
      let(:expected_reason) { "#{trashed_file_version.kind} Not Purgable" }
      let(:expected_suggestion) { "#{trashed_file_version.kind} is not Purgable" }
    end

    it_behaves_like 'a kinded resource' do
      let(:resource_kind) { 'invalid-kind' }
    end

    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'
    it_behaves_like 'an annotate_audits endpoint' do
      let(:expected_response_status) { 204 }
    end

    it 'purges the object' do
      is_expected.to eq(204)
      trashed_resource.reload
      expect(trashed_resource.is_purged).to be_truthy
    end

    it_behaves_like 'a software_agent accessible resource' do
      let(:expected_response_status) { 204 }
      it 'purges the object' do
        is_expected.to eq(204)
        trashed_resource.reload
        expect(trashed_resource.is_purged).to be_truthy
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 204 }
      end
    end

    context 'object is not Purgable' do
      let(:resource) { project }
      let(:resource_id) { project.id }
      let(:resource_kind) { project.kind }

      before do
        resource.update_columns(is_deleted: true)
      end
      it_behaves_like 'a client error' do
        let(:expected_response) { 404 }
        let(:expected_reason) { "#{project.kind} Not Purgable" }
        let(:expected_suggestion) { "#{project.kind} is not Purgable" }
      end
    end

    context 'already purged object' do
      let(:resource) { purged_resource }
      let(:resource_id) { purged_resource.id }
      let(:resource_kind) { purged_resource.kind }
      let(:resource_class) { purged_resource.class }

      it 'should return an empty 204 response' do
        is_expected.to eq(204)
        expect(response.status).to eq(204)
        expect(response.body).not_to eq('null')
        expect(response.body).to be
      end
    end
  end
end
