require 'rails_helper'

describe DDS::V1::FileVersionsAPI do
  include_context 'with authentication'
  include_context 'mock all Uploads StorageProvider'

  let(:project) { FactoryBot.create(:project) }
  let(:project_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }
  let(:data_file) { FactoryBot.create(:data_file, project: project) }
  let(:file_version) { data_file.file_versions.first }
  let(:upload) { file_version.upload }
  let(:new_upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, :skip_validation, project: project, creator: current_user, is_consistent: true) }
  let(:current_file_version) do
    expect(data_file.update(upload: new_upload)).to be_truthy
    data_file.current_file_version
  end
  let(:file_version_stub) { FactoryBot.build(:file_version, data_file: data_file) }
  let(:deleted_file_version) { FactoryBot.create(:file_version, :deleted, data_file: data_file) }
  let(:deleted_data_file) { FactoryBot.create(:data_file, :deleted, project: project) }

  let(:other_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user) }
  let(:other_data_file) { FactoryBot.create(:data_file, project: other_permission.project) }
  let(:other_file_version) { FactoryBot.create(:file_version, data_file: other_data_file) }

  let(:resource_class) { FileVersion }
  let(:resource_serializer) { FileVersionSerializer }
  let!(:resource) { file_version }
  let!(:resource_id) { resource.id }
  let!(:resource_permission) { project_permission }
  let(:resource_stub) { file_version_stub }

  describe 'File versions collection' do
    let(:url) { "/api/v1/files/#{file_id}/versions" }
    let(:file_id) { data_file.id }

    describe 'GET' do
      subject { get(url, headers: headers) }

      it_behaves_like 'a listable resource' do
        let(:expected_list_length) { expected_resources.length }
        let!(:expected_resources) { [
          file_version,
          deleted_file_version
        ]}
        let!(:unexpected_resources) { [
          other_file_version
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      context 'with invalid file_id' do
        let(:file_id) { 'notfoundid' }
        let(:resource_class) { DataFile }
        it_behaves_like 'an identified resource'
      end

      context 'when file is deleted' do
        let(:data_file) { deleted_data_file }
        it_behaves_like 'a listable resource'
      end
    end
  end

  describe 'File version instance' do
    let(:url) { "/api/v1/file_versions/#{resource_id}" }

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
      let(:payload) {{
        label: resource_stub.label
      }}

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an annotate_audits endpoint'
      it_behaves_like 'a logically deleted resource'

      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint'
      end

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end

    describe 'DELETE' do
      subject { delete(url, headers: headers) }
      let(:called_action) { 'DELETE' }

      before { expect(current_file_version).to be_persisted }
      it { expect(resource.deletion_allowed?).to be_truthy }
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

      context 'resource is current_file_version' do
        let(:resource) { current_file_version }
        it { expect(resource.deletion_allowed?).to be_falsey }
        it_behaves_like 'a validated resource'
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

  describe 'Get file version download url' do
    let(:url) { "/api/v1/file_versions/#{resource_id}/url" }
    let(:resource_serializer) { FileVersionUrlSerializer }

    describe 'GET' do
      let(:fingerprint) { FactoryBot.create(:fingerprint, upload: upload) }
      subject { get(url, headers: headers) }

      before do
        expect(fingerprint).to be_persisted
        expect(upload).to be_valid
      end

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

  describe 'Promote file version' do
    let(:url) { "/api/v1/file_versions/#{resource_id}/current" }

    describe 'POST' do
      subject { post(url, headers: headers) }
      let(:called_action) { 'POST' }
      before { expect(current_file_version).to be_persisted }

      it_behaves_like 'a creatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a logically deleted resource'
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 201 }
      end
      it 'promotes the file_version to the current_file_version' do
        expect(data_file.reload).to be_truthy
        expect(data_file.current_file_version).to eq(current_file_version)
        expect(data_file.upload).to eq(current_file_version.upload)
        expect(data_file.upload).not_to eq(resource.upload)
        is_expected.to eq(201)
        reloaded_data_file = DataFile.find(data_file.id)
        expect(reloaded_data_file.current_file_version).not_to eq(current_file_version)
        expect(reloaded_data_file.current_file_version.upload).to eq(resource.upload)
        expect(reloaded_data_file.current_file_version.label).to eq(resource.label)
        expect(reloaded_data_file.current_file_version.version_number).to be > resource.version_number
        expect(reloaded_data_file.upload).to eq(resource.upload)
      end

      it_behaves_like 'a software_agent accessible resource' do
        let(:expected_response_status) { 201 }
        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 201 }
        end
      end

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      context 'resource is current_file_version' do
        let(:resource) { current_file_version }
        it 'should not be duplicated' do
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
        it_behaves_like 'a validated resource'
      end
    end
  end
end
