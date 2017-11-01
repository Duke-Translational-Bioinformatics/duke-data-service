require 'rails_helper'

describe DDS::V1::TrashbinAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:upload) { FactoryGirl.create(:upload, :completed, :with_fingerprint, project: project, creator: current_user, is_consistent: true) }
  let(:parent_folder) { FactoryGirl.create(:folder, project: project) }
  let(:trashed_resource) { FactoryGirl.create(:data_file, :deleted, project: project, upload: upload) }
  let(:untrashed_resource) { FactoryGirl.create(:data_file, project: project, upload: upload) }
  let(:purged_resource) { FactoryGirl.create(:data_file, :purged, project: project, upload: upload) }

  describe '/trashbin/{object_kind}/{object_id}' do
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}" }
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
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}" }
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:called_action) { 'PUT' }
    let(:parent_kind) { parent_folder.kind }
    let(:parent_id) { parent_folder.id }
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
      let(:resource_id) { purged_resource.id }
    end

    it_behaves_like 'an identified resource' do
      let(:parent_id) { "doesNotExist" }
    end

    it_behaves_like 'an identified resource' do
      before do
        parent.update_columns(is_deleted: true)
      end
    end

    it_behaves_like 'a kinded resource' do
      let(:resource_kind) { 'invalid-kind' }
    end

    it_behaves_like 'a kinded resource' do
      let(:parent_kind) { 'invalid-kind' }
    end

    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'
    it_behaves_like 'an annotate_audits endpoint'

    it_behaves_like 'an updatable resource' do
      it 'restores the object to the requested parent' do
        is_expected.to eq(201)
        trashed_resource.reload
        expect(trashed_resource.is_deleted).to be_falsey
        expect(trashed_resource.parent.id).to eq(parent_id)
      end

      it_behaves_like 'a software_agent accessible resource' do
        it 'restores the object to the requested parent' do
          is_expected.to eq(200)
          trashed_resource.reload
          expect(trashed_resource.is_deleted).to be_falsey
          expect(trashed_resource.parent.id).to eq(parent_id)
        end

        it_behaves_like 'an annotate_audits endpoint'
      end
    end

    context 'file_version' do
      context 'containing file not deleted' do
        let(:file_version) {
          fv = untrashed_resource.file_versions.first
          fv.update_columns(is_deleted: true)
        }
        let(:resource_kind) { file_version.kind }
        let(:payload) {{}}
        it_behaves_like 'an updatable resource' do
          it 'restores the object' do
            expect(file_version.is_deleted).to be_truthy
            is_expected.to eq(201)
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

        it_behaves_like 'an identified resource'
      end

      context 'data_file with multiple deleted file_versions'
      let(:deleted_file_versions) { FactoryGirl.create_list(:file_version, 3, :deleted, data_file: trashed_resource) }

        it_behaves_like 'an updatable resource' do
          it 'restores the file and all file_versions to the requested parent' do
            deleted_file_versions.each do |fv|
              expect(fv.is_deleted).to be_truthy
            end
            is_expected.to eq(201)
            trashed_resource.reload
            expect(trashed_resource.is_deleted).to be_falsey
            expect(trashed_resource.parent.id).to eq(parent_id)
            deleted_file_versions.each do |fv|
              expect(fv.is_deleted).to be_falsey
            end
          end
        end
      end
    end
  end

  describe 'PUT /trashbin/{object_kind}/{object_id}/purge' do
    let(:url) { "/api/v1/trashbin/#{resource_kind}/#{resource_id}" }
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:called_action) { 'PUT' }
    let(:trashed_file_version) {
      fv = trashed_resource.file_versions.first
      fv.update_columns(is_deleted: true)
    }
    let(:resource_kind) { trashed_resource.kind }
    let(:resource_id) { trashed_resource.id }
    let(:payload) {{}}

    it_behaves_like 'an identified resource' do
      let(:resource_id) { "doesNotExist" }
    end

    it_behaves_like 'an identified resource' do
      let(:resource_id) { untrashed_resource.id }
    end

    it_behaves_like 'an identified resource' do
      let(:resource_id) { purged_resource.id }
    end

    it_behaves_like 'an identified resource' do
      let(:resource_id) { trashed_file_version.id }
      let(:resource_kind) { trashed_file_version.kind }
    end

    it_behaves_like 'a kinded resource' do
      let(:resource_kind) { 'invalid-kind' }
    end

    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'
    it_behaves_like 'an annotate_audits endpoint'

    it_behaves_like 'an updatable resource' do
      it 'purges the object' do
        is_expected.to eq(201)
        trashed_resource.reload
        expect(trashed_resource.is_purged).to be_truty
      end

      it_behaves_like 'a software_agent accessible resource' do
        it 'purges the object' do
          is_expected.to eq(201)
          trashed_resource.reload
          expect(trashed_resource.is_purged).to be_truty
        end

        it_behaves_like 'an annotate_audits endpoint'
      end
    end
  end
end
