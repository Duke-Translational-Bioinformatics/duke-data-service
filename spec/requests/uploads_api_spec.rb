require 'rails_helper'

describe DDS::V1::UploadsAPI do
  include_context 'with authentication'

  let(:project) { FactoryGirl.create(:project) }
  let!(:storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
  let(:upload) { FactoryGirl.create(:upload, storage_provider_id: storage_provider.id, project: project) }
  let(:other_upload) { FactoryGirl.create(:upload, storage_provider_id: storage_provider.id) }
  let(:completed_upload) { FactoryGirl.create(:upload, :with_fingerprint, :completed, storage_provider_id: storage_provider.id, project: project) }

  let(:chunk) { FactoryGirl.create(:chunk, upload_id: upload.id, number: 1) }

  let(:user) { FactoryGirl.create(:user) }
  let(:upload_stub) { FactoryGirl.build(:upload, storage_provider_id: storage_provider.id) }
  let(:chunk_stub) { FactoryGirl.build(:chunk, upload_id: upload.id) }
  let(:fingerprint_stub) { FactoryGirl.build(:fingerprint) }

  let(:resource_class) { Upload }
  let(:resource_serializer) { UploadSerializer }
  let!(:resource) { upload }
  let!(:resource_permission) { FactoryGirl.create(:project_permission, :project_admin, user: current_user, project: project) }

  describe 'Uploads collection' do
    let(:url) { "/api/v1/projects/#{project_id}/uploads" }
    let(:project_id) { project.id }

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
        let(:extras) { FactoryGirl.create_list(:upload, 5, project: project, storage_provider_id: storage_provider.id) }
      end

      it_behaves_like 'a logically deleted resource' do
        let(:deleted_resource) { project }
      end
      it_behaves_like 'a software_agent accessible resource'
    end

    #Initiate a chunked file upload for a project
    describe 'POST' do
      subject { post(url, payload.to_json, headers) }
      let(:called_action) { "POST" }
      let!(:payload) {{
        name: upload_stub.name,
        content_type: upload_stub.content_type,
        size: upload_stub.size
      }}

      it_behaves_like 'a creatable resource' do
        it 'should set creator' do
          is_expected.to eq(expected_response_status)
          expect(new_object.creator_id).to eq(current_user.id)
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
    end
  end

  describe 'Upload instance' do
    let(:url) { "/api/v1/uploads/#{resource_id}" }
    let(:resource_id) { resource.id }

    #View upload details/status
    describe 'GET' do
      subject { get(url, headers: headers) }

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

    describe 'PUT' do
      subject { put(url, payload.to_json, headers) }
      let(:called_action) { "PUT" }
      let!(:payload) {{
        number: payload_chunk_number,
        size: chunk_stub.size,
        hash: {
          value: chunk_stub.fingerprint_value,
          algorithm: chunk_stub.fingerprint_algorithm
        }
      }}
      let(:payload_chunk_number) { chunk_stub.number }
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
          chunk_stub.save
          chunk_stub
        }
        it_behaves_like 'an updatable resource' do
          it 'updates the expiration on the signed url' do
            expect(resource.updated_at).to eq(resource.created_at)
            sleep 1
            orig_obj = resource_serializer.new(resource).as_json
            orig_temp_url_expires = URI.decode_www_form(URI.parse(orig_obj[:url]).query).assoc('temp_url_expires')[1]
            is_expected.to eq(expected_response_status)
            resource.reload
            expect(resource.updated_at).not_to eq(resource.created_at)
            new_obj = resource_serializer.new(resource).as_json
            new_temp_url_expires = URI.decode_www_form(URI.parse(new_obj[:url]).query).assoc('temp_url_expires')[1]
            expect(new_temp_url_expires).not_to eq(orig_temp_url_expires)
          end
        end
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
        let(:audit_should_include) { {user: current_user, audited_parent: 'Upload'} }
      end
      it_behaves_like 'an annotate_audits endpoint' do
        let(:resource_class) { Chunk }
      end
      it_behaves_like 'a software_agent accessible resource' do
        it_behaves_like 'an annotate_audits endpoint' do
          let(:audit_should_include) { {user: current_user, audited_parent: 'Upload', software_agent: software_agent} }
        end
        it_behaves_like 'an annotate_audits endpoint' do
          let(:resource_class) { Chunk }
        end
      end
    end
  end

  describe 'Complete the chunked file upload', vcr: {record: :new_episodes} do #:vcr do
    let(:url) { "/api/v1/uploads/#{resource_id}/complete" }
    let(:resource_id) { resource.id }
    let(:called_action) { "PUT" }
    subject { put(url, payload.to_json, headers) }
    let!(:payload) {{
      hash: {
        value: fingerprint_stub.value,
        algorithm: fingerprint_algorithm
      }
    }}
    let(:fingerprint_algorithm) { fingerprint_stub.algorithm }

    before do
      expect(chunk).to be_persisted
      actual_size = 0
      storage_provider.put_container(project.id)
      resource.chunks.each do |chunk|
        object = [resource.id, chunk.number].join('/')
        body = 'this is a chunk'
        storage_provider.put_object(
          project.id,
          object,
          body
        )
        chunk.update_attributes({
          fingerprint_value: Digest::MD5.hexdigest(body),
          size: body.length
        })
        actual_size = body.length + actual_size
      end
      resource.update_attribute(:size, actual_size)
    end

    after do
      resource.chunks.each do |chunk|
        object = [resource.id, chunk.number].join('/')
        storage_provider.delete_object(resource.project.id, object)
      end
    end

    it_behaves_like 'an updatable resource'
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

    it_behaves_like 'an annotate_audits endpoint'
    it_behaves_like 'a software_agent accessible resource' do
      it_behaves_like 'an annotate_audits endpoint'
    end
    it_behaves_like 'a storage_provider backed resource' do
      it 'should return an error if the reported size does not match storage_provider computed size' do
        resource.update_attribute(:size, resource.size - 1)
        is_expected.to eq(400)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('error')
        expect(response_json['error']).to eq('400')
        expect(response_json).to have_key('reason')
        expect(response_json['reason']).to eq('IntegrityException')
        expect(response_json).to have_key('suggestion')
        expect(response_json['suggestion']).to eq('reported size does not match size computed by StorageProvider')
      end

      it 'should return an error if the reported chunk hash does not match storage_provider computed size' do
        chunk.update_attribute(:fingerprint_value, "NOTTHECOMPUTEDHASH")
        is_expected.to eq(400)
        expect(response.body).to be
        expect(response.body).not_to eq('null')
        response_json = JSON.parse(response.body)
        expect(response_json).to have_key('error')
        expect(response_json['error']).to eq('400')
        expect(response_json).to have_key('reason')
        expect(response_json['reason']).to eq('IntegrityException')
        expect(response_json).to have_key('suggestion')
        expect(response_json['suggestion']).to eq('reported chunk hash does not match that computed by StorageProvider')
      end
    end
  end

  describe 'Report upload hash' do
    subject { put(url, payload.to_json, headers) }
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
