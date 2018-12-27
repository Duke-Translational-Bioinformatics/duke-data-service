require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'
  include_context 'mock all Uploads StorageProvider'

  let(:project) { FactoryBot.create(:project) }
  let(:upload) { FactoryBot.create(:upload, :with_chunks, project: project, storage_provider: mocked_storage_provider) }
  let(:chunk) { upload.chunks.first }

  let(:other_upload) { FactoryBot.create(:upload, storage_provider: mocked_storage_provider) }
  let(:completed_upload) { FactoryBot.create(:upload, :with_fingerprint, :completed, project: project, storage_provider: mocked_storage_provider) }

  let(:user) { FactoryBot.create(:user) }
  let(:upload_stub) { FactoryBot.build(:upload) }
  let(:chunk_stub) { FactoryBot.build(:chunk, upload_id: upload.id) }
  let(:fingerprint_stub) { FactoryBot.build(:fingerprint) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { UploadSerializer }
  let!(:resource) { upload }
  let!(:resource_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }

  before do
    allow_any_instance_of(Chunk).to receive(:storage_provider)
      .and_return(mocked_storage_provider)
  end

  describe 'Uploads collection' do
    let(:url) { "/api/v1/projects/#{project_id}/uploads" }
    let(:project_id) { project.id }
    let(:payload) {{}}

    #List file uploads for a project
    it_behaves_like 'a GET request' do
      it_behaves_like 'a listable resource' do
        let(:unexpected_resources) { [
          other_upload
        ] }
      end

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'an authorized resource'

      it_behaves_like 'an identified resource' do
        let(:project_id) { "doesNotExist" }
        let(:resource_class) { Project }
      end

      it_behaves_like 'a paginated resource' do
        let(:expected_total_length) { project.uploads.count }
        let(:extras) { FactoryBot.create_list(:upload, 5, project: project) }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'a software_agent accessible resource'
    end

    #Initiate a chunked file upload for a project
    describe 'POST' do
      let!(:payload) {{
        name: upload_stub.name,
        content_type: upload_stub.content_type,
        size: upload_stub.size
      }}

      before do
        allow(StorageProvider).to receive(:default)
          .and_return(mocked_storage_provider)
      end

      it_behaves_like 'a POST request' do
        let(:expected_response_headers) {{
          'X-MIN-CHUNK-UPLOAD-SIZE' => upload_stub.minimum_chunk_size,
          'X-MAX-CHUNK-UPLOAD-SIZE' => upload_stub.max_size_bytes
        }}

        it_behaves_like 'a creatable resource' do
          it 'should set creator' do
            is_expected.to eq(expected_response_status)
            expect(new_object.creator_id).to eq(current_user.id)
          end
          it 'should return chunk-upload-size response headers' do
             is_expected.to eq(expected_response_status)
             expect(response.headers.to_h).to include(expected_response_headers)
          end
        end

        it_behaves_like 'a validated resource' do
          let(:payload) {{
            name: nil,
            content_type: nil,
            size: nil
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
          let(:project_id) { "doesNotExist" }
          let(:resource_class) { Project }
        end

        it_behaves_like 'an annotate_audits endpoint' do
          let(:expected_response_status) { 201 }
        end
        it_behaves_like 'a software_agent accessible resource' do
          let(:expected_response_status) { 201 }
          it_behaves_like 'an annotate_audits endpoint' do
            let(:expected_response_status) { 201 }
          end
        end
        it_behaves_like 'a logically deleted resource' do
          let(:deleted_resource) { project }
        end
        it_behaves_like 'an eventually consistent resource', :project
      end
    end
  end

  describe 'Upload instance' do
    let(:url) { "/api/v1/uploads/#{resource_id}" }
    let(:resource_id) { resource.id }
    let(:payload) {{}}

    #View upload details/status
    it_behaves_like 'a GET request' do
      it_behaves_like 'a viewable resource'

      it_behaves_like 'an authenticated resource'
      it_behaves_like 'a software_agent accessible resource'
      it_behaves_like 'an authorized resource'
      it_behaves_like 'an identified resource' do
        let(:resource_id) { "doesNotExist" }
      end
    end
  end

  describe 'Get pre-signed URL to upload a chunk' do
    let(:resource_class) { Chunk }
    let(:resource_serializer) { ChunkSerializer }
    let!(:resource) { chunk }
    let!(:url) { "/api/v1/uploads/#{upload_id}/chunks" }
    let(:upload_id) { upload.id }
    let(:payload) {{
      number: payload_chunk_number,
      size: chunk_stub.size,
      hash: {
        value: chunk_stub.fingerprint_value,
        algorithm: chunk_stub.fingerprint_algorithm
      }
    }}
    let(:payload_chunk_number) { chunk_stub.number }

    it_behaves_like 'a PUT request' do
      it_behaves_like 'a creatable resource' do
        let(:expected_response_status) {200}
        let(:new_object) {
          resource_class.where(
            upload_id: upload.id,
            number: payload[:number],
            size: payload[:size],
            fingerprint_value: payload[:hash][:value],
            fingerprint_algorithm: payload[:hash][:algorithm]
          ).last
        }
      end

      context 'retry' do
        let(:resource) {
          chunk_stub.save(validate: false)
          chunk_stub
        }
        it_behaves_like 'a viewable resource'
      end

      context 'when chunk.number exists' do
        let(:payload_chunk_number) { chunk.number }
        it_behaves_like 'an updatable resource'
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
        let(:upload_id) { "doesNotExist" }
        let(:resource_class) {"Upload"}
      end

      it_behaves_like 'an annotate_audits endpoint' do
        let(:resource_class) { Chunk }
      end
      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint' do
          let(:resource_class) { Chunk }
        end
      end

      context 'chunk#upload_ready? is false' do
        before(:example) do
          allow_any_instance_of(Chunk).to receive(:upload_ready?).and_return(false)
        end
        it 'returns 404 with a consistency error message' do
          is_expected.to eq(404)
          expect(response.body).to include 'resource_not_consistent'
        end
      end

      context 'chunk size too large' do
        before do
          chunk_stub.size = chunk_stub.chunk_max_size_bytes + 1
        end
        it_behaves_like 'a validated resource' do
          it 'should not persist changes' do
            expect(resource).to be_persisted
            expect {
              is_expected.to eq(400)
            }.not_to change{resource_class.count}
          end
        end
      end

      context 'storage_provider.chunk_max_number exceeded' do
        let(:other_chunk) { FactoryBot.create(:chunk, upload_id: upload.id, number: 2) }
        before do
          allow(mocked_storage_provider).to receive(:chunk_max_reached?)
            .and_return(true)
        end

        it_behaves_like 'a validated resource' do
          let(:expected_reason) { 'maximum upload chunks exceeded.' }
          let(:expected_suggestion) { '' }
          let(:expects_errors) { false }

          it 'should not persist changes' do
            expect(resource).to be_persisted
            expect {
              is_expected.to eq(400)
            }.not_to change{resource_class.count}
          end
        end
      end
    end
  end

  describe 'Complete the chunked file upload' do
    let(:url) { "/api/v1/uploads/#{resource_id}/complete" }
    let(:resource_id) { resource.id }
    let(:called_action) { "PUT" }
    subject { put(url, params: payload.to_json, headers: headers) }
    let!(:payload) {{
      hash: {
        value: fingerprint_stub.value,
        algorithm: fingerprint_algorithm
      }
    }}
    let(:fingerprint_algorithm) { fingerprint_stub.algorithm }

    it_behaves_like 'an updatable resource' do
      let(:expected_response_status) { 202 }
    end
    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'

    it_behaves_like 'an identified resource' do
      let(:resource_id) { "doesNotExist" }
    end

    context 'with completed upload' do
      let(:upload) { completed_upload }
      it_behaves_like 'a validated resource'
    end

    context 'with invalid fingerprint algorithm' do
      let(:fingerprint_algorithm) { 'BadAlgorithm' }
      it_behaves_like 'a validated resource'
    end

    it_behaves_like 'an annotate_audits endpoint' do
      let(:expected_response_status) { 202 }
    end
    it_behaves_like 'a software_agent accessible resource' do
      let(:expected_response_status) { 202 }
      it_behaves_like 'an annotate_audits endpoint' do
        let(:expected_response_status) { 202 }
      end
    end
  end

  describe 'Report upload hash' do
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:url) { "/api/v1/uploads/#{parent_id}/hashes" }
    let!(:parent_id) { completed_upload.id }
    let(:called_action) { "PUT" }
    let!(:payload) {{
      value: fingerprint_stub.value,
      algorithm: fingerprint_stub.algorithm
    }}
    let(:resource_class) { Fingerprint }

    it_behaves_like 'a creatable resource' do
      let(:expected_response_status) {200}
      let(:new_object) { completed_upload.reload }
    end
    it_behaves_like 'an authenticated resource'
    it_behaves_like 'an authorized resource'

    it_behaves_like 'an identified resource' do
      let(:parent_id) { "notexist" }
      let(:resource_class) { Upload }
    end

    it_behaves_like 'an annotate_audits endpoint'

    it_behaves_like 'a software_agent accessible resource' do
      it_behaves_like 'an annotate_audits endpoint'
    end

    context 'with nil payload values' do
      let(:payload) {{
        value: nil,
        algorithm: nil
      }}
      it_behaves_like 'a validated resource'
      it 'should not persist changes' do
        expect {
          is_expected.to eq(400)
        }.not_to change{resource_class.count}
      end
    end

    context 'with incomplete upload' do
      let(:parent_id) { upload.id }
      it_behaves_like 'a validated resource'
      it 'should not persist changes' do
        expect {
          is_expected.to eq(400)
        }.not_to change{resource_class.count}
      end
    end
  end
end
