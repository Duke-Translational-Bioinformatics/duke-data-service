require 'rails_helper'

RSpec.describe S3StorageProvider, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  subject { FactoryBot.build(:s3_storage_provider) }
  let(:project) { stub_model(Project, id: SecureRandom.uuid) }
  let(:chunked_upload) { FactoryBot.create(:chunked_upload, :skip_validation) }
  let(:non_chunked_upload) { FactoryBot.create(:non_chunked_upload, :skip_validation) }
  let(:chunk) { FactoryBot.create(:chunk, :skip_validation, chunked_upload: chunked_upload) }
  let(:domain) { Faker::Internet.domain_name }
  let(:s3_part_max_number) { 10_000 }
  let(:s3_part_max_size) { 5_368_709_120 } # 5GB
  let(:s3_multipart_upload_max_size) { 5_497_558_138_880 } # 5TB
  let(:s3_upload_max_size) { 5_368_709_120 } # 5GB

  shared_context 'stubbed subject#client' do
    let(:stubbed_client) {
      Aws::S3::Client.new(stub_responses: true)
    }
    before { allow(subject).to receive(:client).and_return(stubbed_client) }
  end

  def storage_provider_exception_wrapped_s3_error(aws_error)
    Proc.new do |error|
      expect(error).to be_a StorageProviderException
      expect(error.cause).to be_a "Aws::S3::Errors::#{aws_error}".constantize
      expect(error.message).to eq(error.cause.message)
    end
  end

  it_behaves_like 'A StorageProvider implementation'

  # Validations
  it { is_expected.to validate_presence_of :url_root }
  it { is_expected.to allow_value("http://#{domain}").for(:url_root) }
  it { is_expected.to allow_value("https://#{domain}").for(:url_root) }
  it { is_expected.not_to allow_value(domain).for(:url_root) }
  it { is_expected.to validate_presence_of :service_user }
  it { is_expected.to validate_presence_of :service_pass }

  describe '#minimum_chunk_number' do
    it { expect(subject.minimum_chunk_number).to eq 1 }
  end

  describe '#chunk_max_number' do
    it { expect(subject.chunk_max_number).to eq s3_part_max_number }
  end

  describe '#chunk_max_size_bytes' do
    it { expect(subject.chunk_max_size_bytes).to eq s3_part_max_size }
  end

  describe '#configure' do
    it { expect(subject.configure).to eq true }
  end

  describe '#initialize_project' do
    let(:bucket_location) { "/#{project.id}" }
    let(:cb_response) { { location: bucket_location } }
    before(:example) do
      is_expected.to receive(:create_bucket)
        .with(project.id) { cb_response }
    end
    it 'creates a bucket with the project id' do
      is_expected.to receive(:put_bucket_cors).with(project.id).and_return({})
      expect(subject.initialize_project(project)).to eq(bucket_location)
    end

    context 'when #create_bucket raises exception' do
      let(:cb_response) { raise StorageProviderException }
      it 'does not call #put_bucket_cors and raises the exception' do
        is_expected.not_to receive(:put_bucket_cors)
        expect { subject.initialize_project(project) }.to raise_error(StorageProviderException)
      end
    end

    context 'when #put_bucket_cors raises exception' do
      before(:example) do
        is_expected.to receive(:put_bucket_cors)
          .with(project.id)
          .and_raise(StorageProviderException)
      end
      it { expect { subject.initialize_project(project) }.to raise_error(StorageProviderException) }
    end
  end

  describe '#is_initialized?(project)' do
    before(:example) do
      is_expected.to receive(:head_bucket)
        .with(project.id)
        .and_return(head_bucket_response)
    end
    context 'project container exists' do
      let(:head_bucket_response) { {} }
      it { expect(subject.is_initialized?(project)).to be_truthy }
    end

    context 'project container does not exist' do
      let(:head_bucket_response) { false }
      it { expect(subject.is_initialized?(project)).to be_falsey }
    end
  end

  describe '#is_ready?' do
    let(:response) { { buckets: [] } }
    before(:example) do
      is_expected.to receive(:list_buckets) { response }
    end
    it { expect(subject.is_ready?).to be_truthy }

    context 'StorageProviderException raised' do
      let(:response) { raise StorageProviderException }
      it { expect(subject.is_ready?).to be_falsey }
    end
  end

  describe '#single_file_upload_url(non_chunked_upload)' do
    let(:bucket_name) { non_chunked_upload.storage_container }
    let(:object_key) { non_chunked_upload.id }
    let(:object_size) { non_chunked_upload.size }
    let(:expected_url) { '/' + Faker::Internet.user_name }
    let(:pu_response) { subject.url_root + expected_url }
    before(:example) do
      allow(subject).to receive(:presigned_url)
        .with(
          :put_object,
          bucket_name: bucket_name,
          object_key: object_key,
          content_length: object_size
        ) { pu_response }
    end
    it { expect(subject.single_file_upload_url(non_chunked_upload)).to eq expected_url }

    context 'with ChunkedUpload' do
      let(:expected_exception) { "#{chunked_upload} is not a NonChunkedUpload" }
      it { expect { subject.single_file_upload_url(chunked_upload) }.to raise_error(expected_exception) }
    end
  end

  describe '#initialize_chunked_upload' do
    let(:cmu_response) { multipart_upload_id }
    let(:multipart_upload_id) { Faker::Lorem.characters(88) }
    before(:example) do
      allow(subject).to receive(:create_multipart_upload)
    end
    it 'sets and persists chunked_upload#multipart_upload_id' do
      is_expected.to receive(:create_multipart_upload)
        .with(chunked_upload.project.id, chunked_upload.id)
        .and_return(cmu_response)
      expect(chunked_upload.multipart_upload_id).to be_nil
      expect(subject.initialize_chunked_upload(chunked_upload)).to be_truthy
      expect(chunked_upload.reload).to be_truthy
      expect(chunked_upload.multipart_upload_id).to eq(multipart_upload_id)
    end

    context 'with a non-chunked upload' do
      let(:expected_exception) { "#{non_chunked_upload} is not a ChunkedUpload" }
      it 'raises an exception' do
        expect { subject.initialize_chunked_upload(non_chunked_upload) }.to raise_error(expected_exception)
      end
    end
  end

  describe '#chunk_max_reached?' do
    before(:example) { chunk.number = chunk_number }
    context 'chunk.number < chunk_max_number' do
      let(:chunk_number) { subject.chunk_max_number - 1 }
      it { expect(subject.chunk_max_reached?(chunk)).to be_falsey }
    end

    context 'chunk.number = chunk_max_number' do
      let(:chunk_number) { subject.chunk_max_number }
      it { expect(subject.chunk_max_reached?(chunk)).to be_falsey }
    end

    context 'chunk.number > chunk_max_number' do
      let(:chunk_number) { subject.chunk_max_number + 1 }
      it { expect(subject.chunk_max_reached?(chunk)).to be_truthy }
    end
  end

  describe '#max_chunked_upload_size' do
    it 'returns the max value that ChunkedUpload#size can store' do
      expect(subject.max_chunked_upload_size).to eq(s3_multipart_upload_max_size)
    end
  end

  describe '#max_upload_size' do
    it 'returns the max value that NonChunkedUpload#size can store' do
      expect(subject.max_upload_size).to eq(s3_upload_max_size)
    end
  end

  describe '#suggested_minimum_chunk_size' do
    let(:chunked_upload) { stub_model(ChunkedUpload, size: size) }

    context 'chunked_upload.size = 0' do
      let(:size) { 0 }
      it { expect(subject.suggested_minimum_chunk_size(chunked_upload)).to eq(0) }
    end

    context 'chunked_upload.size < storage_provider.chunk_max_number' do
      let(:size) { subject.chunk_max_number - 1 }
      it { expect(subject.suggested_minimum_chunk_size(chunked_upload)).to eq(1) }
    end

    context 'chunked_upload.size > storage_provider.chunk_max_number' do
      let(:size) { subject.chunk_max_number + 1 }
      it { expect(subject.suggested_minimum_chunk_size(chunked_upload)).to eq(2) }
    end
  end

  describe '#verify_upload_integrity' do
    context 'with NonChunkedUpload' do
      let(:fingerprint) { FactoryBot.create(:fingerprint, upload: non_chunked_upload) }
      let(:bucket_name) { non_chunked_upload.storage_container }
      let(:object_key) { non_chunked_upload.id }
      let(:content_length) { non_chunked_upload.size }
      let(:etag) { fingerprint.value }
      let(:ho_response) { {
        content_length: content_length,
        etag: "\"#{etag}\"",
        metadata: {}
      } }
      before(:example) do
        expect(fingerprint).to be_persisted
        allow(subject).to receive(:head_object)
          .with(bucket_name, object_key) { ho_response }
      end
      it { expect { subject.verify_upload_integrity(non_chunked_upload) }.not_to raise_error }

      context 'size mismatch' do
        let(:content_length) { non_chunked_upload.size + 1 }
        it { expect { subject.verify_upload_integrity(non_chunked_upload) }.to raise_error(IntegrityException, /size does not match/) }
      end

      context 'fingerprints missing' do
        before(:example) { non_chunked_upload.fingerprints.destroy_all }
        let(:etag) { SecureRandom.hex(32) }
        it { expect { subject.verify_upload_integrity(non_chunked_upload) }.to raise_error(IntegrityException, /hash value does not match/) }
      end

      context 'fingerprint mismatch' do
        let(:etag) { SecureRandom.hex(32) }
        it { expect { subject.verify_upload_integrity(non_chunked_upload) }.to raise_error(IntegrityException, /hash value does not match/) }
      end

      context 'object_key does not exist' do
        let(:ho_response) { false }
        it { expect { subject.verify_upload_integrity(non_chunked_upload) }.to raise_error(IntegrityException, /not found in object store/) }
      end

      context '#head_object raises StorageProviderException' do
        let(:ho_response) { raise StorageProviderException }
        it { expect { subject.verify_upload_integrity(non_chunked_upload) }.to raise_error(StorageProviderException) }
      end
    end

    context 'with ChunkedUpload' do
      let(:expected_exception) { "#{chunked_upload} is not a NonChunkedUpload" }
      it { expect { subject.verify_upload_integrity(chunked_upload) }.to raise_error(expected_exception) }
    end
  end

  describe '#complete_chunked_upload' do
    context 'with ChunkedUpload' do
      let(:chunked_upload) { FactoryBot.create(:chunked_upload, :skip_validation, multipart_upload_id: multipart_upload_id) }
      let(:chunks) { [
        FactoryBot.create(:chunk, :skip_validation, chunked_upload: chunked_upload, number: 1),
        FactoryBot.create(:chunk, :skip_validation, chunked_upload: chunked_upload, number: 2),
      ] }
      let(:bucket_name) { chunked_upload.storage_container }
      let(:object_key) { chunked_upload.id }
      let(:multipart_upload_id) { Faker::Lorem.characters(88) }
      let(:content_length) { chunked_upload.size }
      let(:parts) { [
        { etag: "\"#{chunks[0].fingerprint_value}\"", part_number: 1 },
        { etag: "\"#{chunks[1].fingerprint_value}\"", part_number: 2 }
      ] }
      let(:cmu_response) { {
        bucket: bucket_name,
        etag: "\"#{Faker::Crypto.md5}\"",
        key: object_key,
        location: "/#{bucket_name}"
      } }
      let(:ho_response) { {
        content_length: content_length,
        etag: "\"#{Faker::Crypto.md5}\"",
        metadata: {}
      } }
      before(:example) do
        is_expected.to receive(:complete_multipart_upload)
          .with(bucket_name, object_key, upload_id: multipart_upload_id, parts: parts) { cmu_response }
        allow(subject).to receive(:head_object)
          .with(bucket_name, object_key)
          .and_return(ho_response)
      end
      it { expect { subject.complete_chunked_upload(chunked_upload) }.not_to raise_error }

      context 'StorageProviderException raised' do
        let(:cmu_response) { raise StorageProviderException }
        it 'raises an IntegrityException' do
          expect { subject.complete_chunked_upload(chunked_upload) }.to raise_error { |error|
            expect(error).to be_an IntegrityException
            expect(error.cause).to be_a StorageProviderException
            expect(error.message).to eq(error.cause.message)
          }
        end
      end

      context 'size mismatch' do
        let(:content_length) { chunked_upload.size - 10 }

        it { expect { subject.complete_chunked_upload(chunked_upload) }.to raise_error(IntegrityException) }
      end
    end
    context 'with non-chunked upload' do
      let(:expected_exception) { "#{non_chunked_upload} is not a ChunkedUpload" }
      it { expect { subject.complete_chunked_upload(non_chunked_upload) }.to raise_error(expected_exception) }
    end
  end

  describe '#is_complete_chunked_upload?(chunked_upload)' do
    let(:bucket_name) { chunked_upload.storage_container }
    let(:object_key) { chunked_upload.id }
    let(:content_length) { chunked_upload.size }
    let(:ho_response) { {
      content_length: content_length,
      etag: "\"#{Faker::Crypto.md5}\"",
      metadata: {}
    } }
    before(:example) do
      allow(subject).to receive(:head_object)
        .with(bucket_name, object_key) { ho_response }
    end

    it { expect(subject.is_complete_chunked_upload?(chunked_upload)).to be_truthy }

    context 'object does not exist' do
      let(:ho_response) { false }
      it { expect(subject.is_complete_chunked_upload?(chunked_upload)).to be_falsey }
    end

    context 'unexpected StorageProviderException' do
      let(:ho_response) { raise StorageProviderException.new('Unexpected') }
      it { expect { subject.is_complete_chunked_upload?(chunked_upload) }.to raise_error(StorageProviderException, 'Unexpected') }
    end
  end

  describe '#chunk_upload_ready?(chunked_upload)' do
    let(:chunked_upload) { FactoryBot.create(:chunked_upload, :skip_validation, multipart_upload_id: multipart_upload_id) }
    let(:multipart_upload_id) { Faker::Lorem.characters(88) }
    it { expect(subject.chunk_upload_ready?(chunked_upload)).to eq true }

    context 'when upload.multipart_upload_id is nil' do
      let(:multipart_upload_id) { nil }
      it { expect(subject.chunk_upload_ready?(chunked_upload)).to eq false }
    end
  end

  describe '#chunk_upload_url(chunk)' do
    let(:chunked_upload) { FactoryBot.create(:chunked_upload, :skip_validation, multipart_upload_id: multipart_upload_id) }
    let(:bucket_name) { chunk.chunked_upload.storage_container }
    let(:object_key) { chunk.chunked_upload.id }
    let(:multipart_upload_id) { Faker::Lorem.characters(88) }
    let(:part_number) { chunk.number }
    let(:part_size) { chunk.size }
    let(:expected_url) { '/' + Faker::Internet.user_name }
    let(:pu_response) { subject.url_root + expected_url }
    before(:example) do
      is_expected.to receive(:presigned_url)
        .with(
          :upload_part,
          bucket_name: bucket_name,
          object_key: object_key,
          upload_id: multipart_upload_id,
          part_number: part_number,
          content_length: part_size
        ) { pu_response }
    end
    it { expect(subject.chunk_upload_url(chunk)).to eq expected_url }

    context 'when ArgumentError raised' do
      let(:pu_response) { raise ArgumentError, 'missing required parameter params[:upload_id]' }
      it 'raises a StorageProviderException' do
        expect { subject.chunk_upload_url(chunk) }.to raise_error { |error|
          expect(error).to be_a StorageProviderException
          expect(error.cause).to be_an ArgumentError
          expect(error.message).to eq('Upload is not ready')
        }
      end
    end
  end

  describe '#download_url' do
    let(:bucket_name) { chunked_upload.storage_container }
    let(:object_key) { chunked_upload.id }
    let(:expected_url) { '/' + Faker::Internet.user_name }
    let(:file_name) { Faker::File.file_name }
    let(:pu_response) { subject.url_root + expected_url }

    context 'without filename argument set' do
      before(:example) do
        is_expected.to receive(:presigned_url)
          .with(
            :get_object,
            bucket_name: bucket_name,
            object_key: object_key
          ).and_return(pu_response)
      end
      it { expect(subject.download_url(chunked_upload)).to eq expected_url }
    end

    context 'with filename argument set' do
      before(:example) do
        is_expected.to receive(:presigned_url)
          .with(
            :get_object,
            bucket_name: bucket_name,
            object_key: object_key,
            response_content_disposition: "attachment; filename=#{file_name}"
          ).and_return(expected_url)
      end
      it { expect(subject.download_url(chunked_upload, file_name)).to eq expected_url }
    end
  end

  describe '#purge' do
    context 'chunked_upload' do
      let(:bucket_name) { chunked_upload.storage_container }
      let(:object_key) { chunked_upload.id }
      let(:response) { {} }
      before(:example) do
        expect(subject).to receive(:delete_object)
          .with(bucket_name, object_key) { response }
      end

      it { expect(subject.purge(chunked_upload)).to be_truthy }

      context 'unexpected StorageProviderException' do
        let(:response) { raise StorageProviderException.new('Unexpected') }
        it { expect { subject.purge(chunked_upload) }.to raise_error(StorageProviderException, 'Unexpected') }
      end
    end

    context 'chunk' do
      before(:example) do
        expect(subject).not_to receive(:delete_object)
      end

      it { expect(subject.purge(chunk)).to be_truthy }
    end

    context 'unsupported object' do
      before(:example) do
        expect(subject).not_to receive(:delete_object)
      end

      let(:expected_exception) { "NotPurgable is not purgable" }
      it { expect { subject.purge("NotPurgable") }.to raise_error(expected_exception) }
    end
  end

  # S3 Interface
  it { is_expected.to respond_to(:client).with(0).arguments }
  describe '#client' do
    let(:uri_parsed_url_root) { URI.parse(subject.url_root) }
    it { expect(subject.client).to be_a Aws::S3::Client }
    it { expect(subject.client.config.region).to eq 'us-east-1' }
    it { expect(subject.client.config.force_path_style).to eq true }
    it { expect(subject.client.config.access_key_id).to eq subject.service_user }
    it { expect(subject.client.config.secret_access_key).to eq subject.service_pass }
    it { expect(subject.client.config.endpoint).to eq uri_parsed_url_root }
    context 'with #force_path_style' do
      before(:example) { subject.force_path_style = path_style }
      context 'set to true' do
        let(:path_style) { true }
        it { expect(subject.client.config.force_path_style).to be_truthy }
      end
      context 'set to false' do
        let(:path_style) { false }
        it { expect(subject.client.config.force_path_style).to be_falsey  }
      end
      context 'set to nil' do
        let(:path_style) { nil }
        it { expect(subject.client.config.force_path_style).to be_truthy }
      end
    end
    it 'reuses the same client object' do
      expect(subject.client).to eq(subject.client)
    end
  end

  it { is_expected.to respond_to(:list_buckets).with(0).arguments }
  describe '#list_buckets' do
    include_context 'stubbed subject#client'
    let(:bucket_array) { [] }
    let(:expected_response) { { buckets: bucket_array } }
    before(:example) do
      subject.client.stub_responses(:list_buckets, expected_response)
    end

    it { expect(subject.list_buckets).to eq([]) }

    context 'with buckets' do
      let(:bucket_array) { [{ name: SecureRandom.uuid }] }
      it { expect(subject.list_buckets).to eq(bucket_array) }
    end

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.list_buckets }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:create_bucket).with(0).arguments }
  it { is_expected.to respond_to(:create_bucket).with(1).argument }
  describe '#create_bucket' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:expected_response) { { location: "/#{bucket_name}" } }
    before(:example) do
      subject.client.stub_responses(:create_bucket, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
    end
    it { expect(subject.create_bucket(bucket_name)).to eq(expected_response) }

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.create_bucket(bucket_name) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:put_bucket_cors).with(0).arguments }
  it { is_expected.to respond_to(:put_bucket_cors).with(1).argument }
  describe '#put_bucket_cors' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:cors_rule) { {
      allowed_methods: %w(GET PUT HEAD POST DELETE),
      allowed_origins: ['*']
    } }
    let(:expected_response) { {} }
    before(:example) do
      subject.client.stub_responses(:put_bucket_cors, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
      expect(subject.client.api_requests.first[:params][:cors_configuration][:cors_rules]).to include(cors_rule)
    end
    it { expect(subject.put_bucket_cors(bucket_name)).to eq(expected_response) }

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.put_bucket_cors(bucket_name) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:head_bucket).with(0).arguments }
  it { is_expected.to respond_to(:head_bucket).with(1).argument }
  describe '#head_bucket' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:expected_response) { {} }
    before(:example) do
      subject.client.stub_responses(:head_bucket, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
    end
    it { expect(subject.head_bucket(bucket_name)).to eq(expected_response) }

    context 'when bucket does not exist' do
      let(:expected_response) { 'NoSuchBucket' }
      it 'rescues from NoSuchBucket exception and returns false' do
        expect {
          expect(subject.head_bucket(bucket_name)).to be_falsey
        }.not_to raise_error
      end
    end

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.head_bucket(bucket_name) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:head_object).with(0).arguments }
  it { is_expected.not_to respond_to(:head_object).with(1).arguments }
  it { is_expected.to respond_to(:head_object).with(2).argument }
  describe '#head_object' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:object_key) { SecureRandom.uuid }
    let(:expected_response) { {
      content_length: Faker::Number.between(1000, 10000),
      etag: "\"#{Faker::Crypto.md5}\"",
      metadata: {}
    } }
    before(:example) do
      subject.client.stub_responses(:head_object, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
      expect(subject.client.api_requests.first[:params][:key]).to eq(object_key)
    end
    it { expect(subject.head_object(bucket_name, object_key)).to eq(expected_response) }

    context 'when object does not exist' do
      let(:expected_response) { 'NoSuchKey' }
      it 'rescues from NoSuchKey exception and returns false' do
        expect {
          expect(subject.head_object(bucket_name, object_key)).to be_falsey
        }.not_to raise_error
      end
    end

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.head_object(bucket_name, object_key) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:create_multipart_upload).with(0..1).arguments }
  it { is_expected.to respond_to(:create_multipart_upload).with(2).arguments }
  describe '#create_multipart_upload' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:object_key) { SecureRandom.uuid }
    let(:expected_upload_id) { Faker::Lorem.characters(88) }
    let(:expected_response) { {
      bucket: bucket_name,
      key: object_key,
      upload_id: expected_upload_id
    } }
    before(:example) do
      subject.client.stub_responses(:create_multipart_upload, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
      expect(subject.client.api_requests.first[:params][:key]).to eq(object_key)
    end
    it { expect(subject.create_multipart_upload(bucket_name, object_key)).to eq(expected_upload_id) }

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.create_multipart_upload(bucket_name, object_key) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:complete_multipart_upload).with(0..1).arguments }
  it { is_expected.not_to respond_to(:complete_multipart_upload).with(2).arguments }
  it { is_expected.to respond_to(:complete_multipart_upload).with(2).arguments.and_keywords(:upload_id, :parts) }
  describe '#complete_multipart_upload' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:object_key) { SecureRandom.uuid }
    let(:multipart_upload_id) { Faker::Lorem.characters(88) }
    let(:parts) { [
      { etag: "\"#{Faker::Crypto.md5}\"", part_number: 1 },
      { etag: "\"#{Faker::Crypto.md5}\"", part_number: 2 }
    ] }
    let(:expected_response) { {
      bucket: bucket_name,
      etag: "\"#{Faker::Crypto.md5}\"",
      key: object_key,
      location: "/#{bucket_name}"
    } }
    before(:example) do
      subject.client.stub_responses(:complete_multipart_upload, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
      expect(subject.client.api_requests.first[:params][:key]).to eq(object_key)
      expect(subject.client.api_requests.first[:params][:upload_id]).to eq(multipart_upload_id)
      expect(subject.client.api_requests.first[:params][:multipart_upload]).to eq({parts: parts})
    end
    it { expect(subject.complete_multipart_upload(bucket_name, object_key, upload_id: multipart_upload_id, parts: parts)).to eq(expected_response) }

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.complete_multipart_upload(bucket_name, object_key, upload_id: multipart_upload_id, parts: parts) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:delete_object).with(0).arguments }
  it { is_expected.not_to respond_to(:delete_object).with(1).arguments }
  it { is_expected.to respond_to(:delete_object).with(2).argument }
  describe '#delete_object' do
    include_context 'stubbed subject#client'
    let(:bucket_name) { SecureRandom.uuid }
    let(:object_key) { SecureRandom.uuid }
    let(:expected_response) { {} }
    before(:example) do
      subject.client.stub_responses(:delete_object, expected_response)
    end
    after(:example) do
      expect(subject.client.api_requests.first).not_to be_nil
      expect(subject.client.api_requests.first[:params][:bucket]).to eq(bucket_name)
      expect(subject.client.api_requests.first[:params][:key]).to eq(object_key)
    end
    it { expect(subject.delete_object(bucket_name, object_key)).to eq(expected_response) }

    context 'when an unexpected S3 error is thrown' do
      let(:expected_response) { 'Unexpected' }
      it 'raises a StorageProviderException' do
        expect { subject.delete_object(bucket_name, object_key) }.to raise_error storage_provider_exception_wrapped_s3_error(expected_response)
      end
    end
  end

  it { is_expected.not_to respond_to(:presigned_url).with(0).arguments }
  it { is_expected.not_to respond_to(:presigned_url).with(1).argument }
  it { is_expected.to respond_to(:presigned_url).with(1).argument.and_keywords(:bucket_name, :object_key) }
  it { is_expected.to respond_to(:presigned_url).with(1).argument.and_keywords(:bucket_name, :object_key, :upload_id, :part_number, :content_length) }
  describe '#presigned_url' do
    around(:example) do |example|
      travel_to(Time.now) do #freeze_time
        example.run
      end
    end
    let(:signer) { Aws::S3::Presigner.new(client: subject.client) }
    let(:bucket_name) { SecureRandom.uuid }
    let(:object_key) { SecureRandom.uuid }
    let(:file_name) { Faker::File.file_name }

    context 'sign :get_object' do
      let(:expected_url) {
        signer.presigned_url(
          :get_object,
          bucket: bucket_name,
          key: object_key,
          response_content_disposition: "attachment; filename=#{file_name}",
          expires_in: subject.signed_url_duration
        )
      }
      it { expect(subject.presigned_url(:get_object, bucket_name: bucket_name, object_key: object_key, response_content_disposition: "attachment; filename=#{file_name}")).to eq expected_url }
    end

    context 'sign :upload_part' do
      let(:multipart_upload_id) { Faker::Lorem.characters(88) }
      let(:part_number) { Faker::Number.between(1, 100) }
      let(:part_size) { Faker::Number.between(1000, 10000) }
      let(:expected_url) {
        signer.presigned_url(
          :upload_part,
          bucket: bucket_name,
          key: object_key,
          upload_id: multipart_upload_id,
          part_number: part_number,
          content_length: part_size,
          expires_in: subject.signed_url_duration
        )
      }
      it { expect(subject.presigned_url(:upload_part, bucket_name: bucket_name, object_key: object_key, upload_id: multipart_upload_id, part_number: part_number, content_length: part_size)).to eq expected_url }

      context 'with nil :upload_id' do
        it { expect { subject.presigned_url(:upload_part, bucket_name: bucket_name, object_key: object_key, upload_id: nil, part_number: part_number, content_length: part_size) }.to raise_error(ArgumentError, 'missing required parameter params[:upload_id]') }
      end
    end

    context 'sign :put_object' do
      let(:object_size) { Faker::Number.between(1000, 10000) }
      let(:expected_url) {
        signer.presigned_url(
          :put_object,
          bucket: bucket_name,
          key: object_key,
          content_length: object_size,
          expires_in: subject.signed_url_duration
        )
      }
      it { expect(subject.presigned_url(:put_object, bucket_name: bucket_name, object_key: object_key, content_length: object_size)).to eq expected_url }
    end
  end
end
