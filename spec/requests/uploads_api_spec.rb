require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'
  include_context 'mock all Uploads StorageProvider'

  let(:project) { FactoryBot.create(:project) }
  let(:default_storage_provider) { FactoryBot.create(:storage_provider, :default) }
  let(:chunked_upload) { FactoryBot.create(:chunked_upload, :with_chunks, project: project, storage_provider: mocked_storage_provider) }
  let(:chunk) { chunked_upload.chunks.first }

  let(:other_chunked_upload) { FactoryBot.create(:chunked_upload, storage_provider: mocked_storage_provider) }
  let(:completed_chunked_upload) { FactoryBot.create(:chunked_upload, :with_fingerprint, :completed, project: project, storage_provider: mocked_storage_provider) }

  let(:user) { FactoryBot.create(:user) }
  let(:upload_stub) { FactoryBot.build(:chunked_upload) }
  let(:chunk_stub) { FactoryBot.build(:chunk, chunked_upload: chunked_upload) }
  let(:fingerprint_stub) { FactoryBot.build(:fingerprint) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { ChunkedUploadSerializer }
  let!(:resource) { chunked_upload }
  let!(:resource_permission) { FactoryBot.create(:project_permission, :project_admin, user: current_user, project: project) }

  before do
    expect(default_storage_provider).to be_persisted
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
          other_chunked_upload
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
        let(:extras) { FactoryBot.create_list(:chunked_upload, 5, project: project) }
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
      let(:storage_is_initialized) { true }

      before do
        expect(StorageProvider.default.project_storage_providers.update_all(is_initialized: storage_is_initialized)).to be_truthy
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

        context 'with chunked set to false' do
          let(:upload_stub) { FactoryBot.build(:non_chunked_upload) }
          let!(:payload) {{
            name: upload_stub.name,
            content_type: upload_stub.content_type,
            size: upload_stub.size,
            chunked: false
          }}
          let(:expected_response_headers) {{
            'X-MAX-UPLOAD-SIZE' => upload_stub.max_size_bytes
          }}
          let(:resource_class) { NonChunkedUpload }
          let(:resource_serializer) { NonChunkedUploadSerializer }
          it_behaves_like 'a creatable resource' do
            it 'should return chunk-upload-size response headers' do
               is_expected.to eq(expected_response_status)
               expect(response.headers.to_h).to include(expected_response_headers)
            end
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
        context 'when project storage is missing' do
          before(:example) do
            expect(project.project_storage_providers.destroy_all).to be_truthy
          end
          it_behaves_like 'an inconsistent resource'
        end
        context 'when project storage is not initialized' do
          let(:storage_is_initialized) { false }
          it_behaves_like 'an inconsistent resource'
        end

        context 'with storage_provider param' do
          let(:new_storage_provider) { FactoryBot.create(:storage_provider) }
          let(:storage_provider_id) { new_storage_provider.id }
          let!(:payload) {{
            name: upload_stub.name,
            content_type: upload_stub.content_type,
            size: upload_stub.size,
            storage_provider: { id: storage_provider_id }
          }}
          let(:new_storage_is_initialized) { true }
          before(:example) do
            expect(new_storage_provider).not_to be_is_default
            expect(new_storage_provider.project_storage_providers.update_all(is_initialized: new_storage_is_initialized)).to be_truthy
          end
          it_behaves_like 'a creatable resource' do
            it 'should set storage_provider' do
              is_expected.to eq(expected_response_status)
              expect(new_object.storage_provider_id).to eq(storage_provider_id)
            end
          end

          context 'when StorageProvider does not exist' do
            let(:storage_provider_id) { 'doesNotExist' }
            let(:resource_class) { "StorageProvider" }
            it_behaves_like 'an identified resource'
          end

          context 'when project storage is not initialized' do
            let(:new_storage_is_initialized) { false }
            it_behaves_like 'an inconsistent resource'
          end

          context 'when StorageProvider is deprecated' do
            before(:example) do
              mocked_storage_provider.is_deprecated = true
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
        end
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
    let(:upload_id) { chunked_upload.id }
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
            upload_id: chunked_upload.id,
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

      context 'chunked_upload#ready_for_chunks? is false' do
        before(:example) do
          allow_any_instance_of(ChunkedUpload).to receive(:ready_for_chunks?).and_return(false)
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
        let(:other_chunk) { FactoryBot.create(:chunk, upload_id: chunked_upload.id, number: 2) }
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
      let(:chunked_upload) { completed_chunked_upload }
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

    context 'when StorageProvider is deprecated' do
      before(:example) do
        mocked_storage_provider.is_deprecated = true
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
  end

  describe 'Report upload hash' do
    subject { put(url, params: payload.to_json, headers: headers) }
    let(:url) { "/api/v1/uploads/#{parent_id}/hashes" }
    let!(:parent_id) { completed_chunked_upload.id }
    let(:called_action) { "PUT" }
    let!(:payload) {{
      value: fingerprint_stub.value,
      algorithm: fingerprint_stub.algorithm
    }}
    let(:resource_class) { Fingerprint }

    it_behaves_like 'a creatable resource' do
      let(:expected_response_status) {200}
      let(:new_object) { completed_chunked_upload.reload }
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
      let(:parent_id) { chunked_upload.id }
      it_behaves_like 'a validated resource'
      it 'should not persist changes' do
        expect {
          is_expected.to eq(400)
        }.not_to change{resource_class.count}
      end
    end
  end
end
