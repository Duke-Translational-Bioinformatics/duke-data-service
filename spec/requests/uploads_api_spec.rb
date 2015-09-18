require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'

  let(:chunk) { FactoryGirl.create(:chunk, :swift) }
  let(:upload) { chunk.upload }
  let(:project) { upload.project }
  let!(:storage_provider) { upload.storage_provider }
  let(:other_upload) { FactoryGirl.create(:upload) }
  let(:user) { FactoryGirl.create(:user) }
  let(:upload_stub) { FactoryGirl.build(:upload) }
  let(:chunk_stub) { FactoryGirl.build(:chunk) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { UploadSerializer }
  let!(:resource) { upload }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, user: current_user, project: upload.project) }

  describe 'Uploads collection' do
    let(:url) { "/api/v1/projects/#{project.id}/uploads" }

    describe 'List file uploads for a project' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_upload
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/uploads" }
        let(:resource_class) { 'Project' }
      end

      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { project.uploads.count }
        let(:extras) { FactoryGirl.create_list(:upload, 5, project_id: project.id) }
      end
    end

    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let!(:payload) {{
        name: upload_stub.name,
        content_type: upload_stub.content_type,
        size: upload_stub.size,
        hash: {
          value: upload_stub.fingerprint_value,
          algorithm: upload_stub.fingerprint_algorithm
        }
      }}

      it_behaves_like 'a creatable resource'

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          name: nil,
          content_type: nil,
          size: nil,
          hash: {
            value: nil,
            algorithm: nil
          }
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/projects/notexists_projectid/uploads" }
        let(:resource_class) { 'Project' }
      end
    end
  end

  describe 'Upload instance' do
    let(:url) { "/api/v1/uploads/#{resource.id}" }

    describe 'GET' do
      subject { get(url, nil, headers) }

      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/uploads/notexists_resourceid" }
      end
    end
  end

  describe 'Get pre-signed URL to upload a chunk', :vcr => {:match_requests_on => [:method, :uri_ignoring_uuids]} do
    let(:resource_class) { Chunk }
    let(:resource_serializer) { ChunkSerializer }
    let!(:resource) { chunk }
    let!(:url) { "/api/v1/uploads/#{upload.id}/chunks" }

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let!(:payload) {{
        number: chunk_stub.number,
        size: chunk_stub.size,
        hash: {
          value: chunk_stub.fingerprint_value,
          algorithm: chunk_stub.fingerprint_algorithm
        }
      }}
      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:new_object) { resource_class.last }
      end

      it_behaves_like 'a validated resource' do
        let(:payload) {{
          number: nil,
          size: nil,
          hash: {
            value: nil,
            algorithm: nil
          }
        }}
        it 'should not persist changes' do
          expect(resource).to be_persisted
          expect {
            is_expected.to eq(400)
          }.not_to change{resource_class.count}
        end
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/uploads/notexists_resourceid/chunks" }
        let(:resource_class) {"Upload"}
      end

      it_behaves_like 'a storage_provider backed resource'
    end
  end

  describe 'Complete the chunked file upload' do
    let(:url) { "/api/v1/uploads/#{resource.id}/complete" }

    describe 'PUT' do
      subject { put(url, nil, headers) }

      it_behaves_like 'an updatable resource'
      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:url) { "/api/v1/uploads/notexists_resourceid/complete" }
      end
    end
  end
end
