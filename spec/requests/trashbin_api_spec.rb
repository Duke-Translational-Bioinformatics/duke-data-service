require 'rails_helper'

describe DDS::V1::TrashbinAPI do
  include_context 'with authentication'

  let(:upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, project: project, creator: current_user, is_consistent: true) }
  let(:project) { FactoryBot.create(:project) }
    let(:parent_folder) { FactoryBot.create(:folder, project: project) }
      let(:named_trashed_child_folder) { FactoryBot.create(:folder, :deleted, name: 'The XXXX trashed child folder', parent: parent_folder, project: project) }
        let(:depth_trashed_resource) { FactoryBot.create(:data_file, :deleted, parent: named_trashed_child_folder, project: project) }
        let(:depth_named_trashed_resource) { FactoryBot.create(:data_file, :deleted, name: 'The XXXX depth trashed resource', parent: named_trashed_child_folder, project: project) }
        let(:depth_purged_resource) { FactoryBot.create(:data_file, :purged, parent: named_trashed_child_folder, project: project) }
        let(:depth_named_purged_resource) { FactoryBot.create(:data_file, :purged, name: 'The XXXX depth trashed resource', parent: named_trashed_child_folder, project: project) }
      let(:trashed_child_resource) { FactoryBot.create(:data_file, :deleted, parent: parent_folder, project: project) }
    let(:trashed_resource) { FactoryBot.create(:data_file, :root, :deleted, project: project, upload: upload) }
    let(:named_trashed_resource) { FactoryBot.create(:data_file, :root, :deleted, name: 'The XXXX trashed resource', project: project, upload: upload) }
    let(:named_untrashed_resource) { FactoryBot.create(:data_file, :root, name: 'The XXXX root resource', project: project, upload: upload) }
    let(:untrashed_resource) { FactoryBot.create(:data_file, :root, project: project, upload: upload) }
    let(:purged_resource) { FactoryBot.create(:data_file, :root, :purged, project: project, upload: upload) }
    let(:named_purged_resource) { FactoryBot.create(:data_file, :root, :purged, name: 'The XXXX purged resource', project: project, upload: upload) }
    let(:named_trashed_folder) { FactoryBot.create(:folder, :root, :deleted, name: 'The XXXX trashed root folder', project: project) }
      let(:named_trashed_resource_in_trashed_folder) { FactoryBot.create(:data_file, :deleted, name: 'The XXXX trashed resource in trashed folder', parent: named_trashed_folder, project: project, upload: upload) }
      let(:trashed_resource_in_trashed_folder) { FactoryBot.create(:data_file, :deleted, parent: named_trashed_folder, project: project, upload: upload) }

  let(:other_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user) }
  let(:other_folder) { FactoryBot.create(:folder, :deleted, project: other_permission.project) }
  let(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
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

  describe 'GET /trashbin/projects/{id}/children{?name_contains}{?recurse}' do
    let(:url) { "/api/v1/trashbin/projects/#{parent_id}/children#{query_params}" }
    let(:parent_id) { project.id }
    let(:payload) {{}}

    context 'default' do
      let(:query_params) { '' }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            trashed_resource,
            named_trashed_resource,
            named_trashed_folder
          ] }
          let(:unexpected_resources) { [
            parent_folder,
            named_trashed_child_folder,
            depth_trashed_resource,
            depth_named_trashed_resource,
            depth_purged_resource,
            depth_named_purged_resource,
            trashed_child_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource,
            named_trashed_resource_in_trashed_folder,
            trashed_resource_in_trashed_folder
          ] }
          it_behaves_like 'a paginated resource' do
            let(:expected_total_length) { project.children.where(is_deleted: true, is_purged: false).count }
            let(:extras) { FactoryBot.create_list(:folder, 5, :deleted, parent: parent_folder, project: project) }
          end
        end

        it_behaves_like 'a sorted index resource', :trashed_resource do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            trashed_resource.touch
          end
        end

        it_behaves_like 'an authenticated resource'
        it_behaves_like 'a software_agent accessible resource'

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

    context 'name_contains' do
      let(:query_params) { "?name_contains=#{name_contains}" }

      describe 'empty string' do
        let(:name_contains) { '' }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [ ] }
            let(:unexpected_resources) { [
              parent_folder,
              named_trashed_child_folder,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              trashed_child_resource,
              trashed_resource,
              named_trashed_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
              named_trashed_folder,
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ] }
          end
        end
      end

      describe 'string without matches' do
        let(:name_contains) { 'name_without_matches' }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [ ] }
            let(:unexpected_resources) { [
              parent_folder,
              named_trashed_child_folder,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              trashed_child_resource,
              trashed_resource,
              named_trashed_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
              named_trashed_folder,
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ] }
          end
        end
      end

      describe 'string with a match' do
        let(:name_contains) { 'XXXX' }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
              named_trashed_resource,
              named_trashed_folder
            ] }
            let(:unexpected_resources) { [
              parent_folder,
              named_trashed_child_folder,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              trashed_child_resource,
              trashed_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ] }
          end
          it_behaves_like 'a sorted index resource', :named_trashed_resource do
            let(:sort_column) { :updated_at }
            let(:sort_order) { "asc" }
            before do
              named_trashed_resource.touch
            end
          end
        end
      end

      describe 'lowercase string with a match' do
        let(:name_contains) { 'xxxx' }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) { [
              named_trashed_resource,
              named_trashed_folder
            ] }
            let(:unexpected_resources) { [
              parent_folder,
              named_trashed_child_folder,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              trashed_child_resource,
              trashed_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ] }
          end

          it_behaves_like 'a sorted index resource', :named_trashed_resource do
            let(:sort_column) { :updated_at }
            let(:sort_order) { "asc" }
            before do
              named_trashed_resource.touch
            end
          end
        end
      end
    end

    context 'recurse' do
      let(:query_params) { "?recurse=true" }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            named_trashed_child_folder,
            depth_trashed_resource,
            depth_named_trashed_resource,
            trashed_child_resource,
            trashed_resource,
            named_trashed_resource,
            named_trashed_folder,
            named_trashed_resource_in_trashed_folder,
            trashed_resource_in_trashed_folder
          ] }
          let(:unexpected_resources) { [
            parent_folder,
            depth_purged_resource,
            depth_named_purged_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource
          ] }
        end

        it_behaves_like 'a sorted index resource', :named_trashed_resource do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            named_trashed_resource.touch
          end
        end
      end
    end

    context 'name_contains and resurse' do
      let(:query_params) { '?recurse=true&name_contains=XXXX' }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            named_trashed_child_folder,
            depth_named_trashed_resource,
            named_trashed_resource,
            named_trashed_folder,
            named_trashed_resource_in_trashed_folder
          ] }
          let(:unexpected_resources) { [
            depth_trashed_resource,
            trashed_child_resource,
            trashed_resource,
            trashed_resource_in_trashed_folder,
            parent_folder,
            depth_purged_resource,
            depth_named_purged_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource
          ] }
        end

        it_behaves_like 'a sorted index resource', :named_trashed_resource do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            named_trashed_resource.touch
          end
        end
      end
    end
  end

  describe 'GET /trashbin/folders/{id}/children{?name_contains}{?recurse}' do
    let(:url) { "/api/v1/trashbin/folders/#{parent_id}/children#{query_params}" }
    let(:payload) {{}}

    context 'default' do
      let(:query_params) { '' }

      context 'untrashed folder' do
        let(:parent_id) { parent_folder.id }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) {[
              named_trashed_child_folder,
              trashed_child_resource
            ]}
            let(:unexpected_resources) { [
              parent_folder,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              trashed_resource,
              named_trashed_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
              named_trashed_folder,
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ] }
          end
          it_behaves_like 'a paginated resource' do
            let(:expected_total_length) { parent_folder.children.count }
            let(:extras) { FactoryBot.create_list(:folder, 5, :deleted, parent: parent_folder, project: project) }
          end

          it_behaves_like 'a sorted index resource', :named_trashed_child_folder do
            let(:sort_column) { :updated_at }
            let(:sort_order) { "asc" }
            before do
              named_trashed_child_folder.touch
            end
          end
        end
      end

      context 'trashed folder' do
        let(:parent_id) { named_trashed_folder.id }

        it_behaves_like 'a GET request' do
          it_behaves_like 'a searchable resource' do
            let(:expected_resources) {[
              named_trashed_resource_in_trashed_folder,
              trashed_resource_in_trashed_folder
            ]}
            let(:unexpected_resources) { [
              parent_folder,
              named_trashed_child_folder,
              trashed_child_resource,
              depth_trashed_resource,
              depth_named_trashed_resource,
              depth_purged_resource,
              depth_named_purged_resource,
              named_untrashed_resource,
              untrashed_resource,
              purged_resource,
              named_purged_resource,
            ] }
          end
          it_behaves_like 'a sorted index resource', :named_trashed_resource_in_trashed_folder do
            let(:sort_column) { :updated_at }
            let(:sort_order) { "asc" }
            before do
              named_trashed_resource_in_trashed_folder.touch
            end
          end
        end
      end
    end

    context 'name_contains' do
      let(:parent_id) { parent_folder.id }
      let(:query_params) { '?name_contains=XXXX' }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            named_trashed_child_folder
          ] }
          let(:unexpected_resources) { [
            parent_folder,
            depth_trashed_resource,
            depth_named_trashed_resource,
            depth_purged_resource,
            depth_named_purged_resource,
            trashed_child_resource,
            trashed_resource,
            named_trashed_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource,
            named_trashed_folder,
            named_trashed_resource_in_trashed_folder,
            trashed_resource_in_trashed_folder
          ] }
        end
        it_behaves_like 'a sorted index resource', :named_trashed_child_folder do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            named_trashed_child_folder.touch
          end
        end
      end
    end

    context 'recurse' do
      let(:parent_id) { parent_folder.id }
      let(:query_params) { '?recurse=true' }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            named_trashed_child_folder,
            trashed_child_resource,
            depth_trashed_resource,
            depth_named_trashed_resource
          ] }
          let(:unexpected_resources) { [
            parent_folder,
            depth_purged_resource,
            depth_named_purged_resource,
            trashed_resource,
            named_trashed_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource,
            named_trashed_folder,
            named_trashed_resource_in_trashed_folder,
            trashed_resource_in_trashed_folder
          ] }
        end
        it_behaves_like 'a sorted index resource', :named_trashed_child_folder do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            named_trashed_child_folder.touch
          end
        end
      end
    end

    context 'name_contains and resurse' do
      let(:parent_id) { parent_folder.id }
      let(:query_params) { '?name_contains=XXXX&recurse=true' }

      it_behaves_like 'a GET request' do
        it_behaves_like 'a searchable resource' do
          let(:expected_resources) { [
            named_trashed_child_folder,
            depth_named_trashed_resource
          ] }
          let(:unexpected_resources) { [
            parent_folder,
            trashed_child_resource,
            depth_trashed_resource,
            depth_purged_resource,
            depth_named_purged_resource,
            trashed_resource,
            named_trashed_resource,
            named_untrashed_resource,
            untrashed_resource,
            purged_resource,
            named_purged_resource,
            named_trashed_folder,
            named_trashed_resource_in_trashed_folder,
            trashed_resource_in_trashed_folder
          ] }
        end
        it_behaves_like 'a sorted index resource', :named_trashed_child_folder do
          let(:sort_column) { :updated_at }
          let(:sort_order) { "asc" }
          before do
            named_trashed_child_folder.touch
          end
        end
      end
    end
  end
end
