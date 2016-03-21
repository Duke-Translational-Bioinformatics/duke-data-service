require 'rails_helper'

describe DDS::V1::FileVersionsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let(:project_permission) { FactoryGirl.create(:project_permission, user: current_user, project: project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project) }
  let(:file_version) { FactoryGirl.create(:file_version, data_file: data_file) }
  let(:file_version_stub) { FactoryGirl.build(:file_version, data_file: data_file) }
  let(:deleted_file_version) { FactoryGirl.create(:file_version, :deleted, data_file: data_file) }
  let(:deleted_data_file) { FactoryGirl.create(:data_file, :deleted, project: project) }

  let(:other_permission) { FactoryGirl.create(:project_permission, user: current_user) }
  let(:other_data_file) { FactoryGirl.create(:data_file, project: other_permission.project) }
  let(:other_file_version) { FactoryGirl.create(:file_version, data_file: other_data_file) }

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
      subject { get(url, nil, headers) }

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
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end
    end

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
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
    end
  end

  describe 'Get file version download url' do
    let(:url) { "/api/v1/file_versions/#{resource_id}/url" }
    let(:resource_serializer) { FileVersionUrlSerializer }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'a software_agent accessible resource'

      it_behaves_like 'an identified resource' do
        let(:resource_id) {'notfoundid'}
      end

      it_behaves_like 'a logically deleted resource'
    end
  end
end
