require 'rails_helper'

RSpec.describe SwiftStorageProvider, type: :model do
  let(:chunk) { FactoryBot.create(:chunk) }
  let(:storage_provider) { FactoryBot.create(:swift_storage_provider) }
  let(:content_type) {'text/plain'}
  let(:filename) {'text_file.txt'}
  subject { storage_provider }


  describe 'StorageProvider Implementation' do
    let(:expected_project_id) { SecureRandom.uuid }
    let(:project) { instance_double("Project") }
    let(:upload) { FactoryBot.create(:upload, :with_chunks) }
    let(:expected_meta) {
      {
      "content-length" => "#{upload.size}"
      }
    }
    let(:chunk) { FactoryBot.create(:chunk) }

    it_behaves_like 'A StorageProvider'

    it {
      expect(project).to receive(:id)
        .and_return(expected_project_id)
      is_expected.to receive(:put_container)
        .with(expected_project_id)

      expect {
        subject.initialize_project(project)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:build_signed_url)
        .with(
          'POST',
          upload.sub_path,
          subject.expiry
        )
      expect {
        subject.single_file_upload_url(upload)
      }.not_to raise_error
    }

    it {
      expect {
        subject.initialize_chunked_upload(upload)
      }.not_to raise_error
    }

    it {
      expect {
        expect(subject.endpoint).to eq(subject.url_root)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:put_object_manifest)
        .with(
          upload.storage_container,
          upload.id,
          upload.manifest,
          upload.content_type,
          upload.name
        )
      is_expected.to receive(:get_object_metadata)
        .with(
          upload.storage_container,
          upload.id
        ).and_return(expected_meta)

      expect {
        subject.complete_chunked_upload(upload)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:build_signed_url)
        .with(
          'PUT',
          chunk.sub_path,
          subject.expiry
        )
      expect {
        subject.chunk_upload_url(chunk)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:build_signed_url)
        .with(
          'GET',
          upload.sub_path,
          subject.expiry,
          upload.name
        )
      expect {
        subject.download_url(upload)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:delete_object_manifest)
        .with(
          upload.storage_container,
          upload.id
        )
      expect {
        subject.purge(upload)
      }.not_to raise_error
    }

    it {
      is_expected.to receive(:delete_object)
        .with(
          chunk.storage_container,
          chunk.object_path
        )

      expect {
        subject.purge(chunk)
      }.not_to raise_error
    }

    it {
      expect {
        subject.purge(subject)
      }.to raise_error("#{subject} is not purgable")
    }
  end

  describe 'methods that call swift api', :vcr do
    let(:container_name) { 'the_container' }
    let(:object_name) { 'the_object' }
    let(:slo_name) { 'the_slo' }
    let(:segment_name) { [object_name, 1].join('/') }
    let(:segment_path) { [container_name, segment_name].join('/') }
    let(:object_body) { 'This is the object body!' }
    let(:manifest_hash) { [ {
      path: segment_path,
      etag: Digest::MD5.hexdigest(object_body),
      size_bytes: object_body.length
    } ] }

    it 'should respond to auth_token' do
      is_expected.to respond_to :auth_token
      expect { subject.auth_token }.not_to raise_error
      expect(subject.auth_token).to be_a String
    end

    it 'should respond to auth_header' do
      is_expected.to respond_to :auth_header
      expect { subject.auth_header }.not_to raise_error
      expect(subject.auth_header).to be_a Hash
    end

    it 'should respond to storage_url' do
      is_expected.to respond_to :storage_url
      expect { subject.storage_url }.not_to raise_error
      expect(subject.storage_url).to be_a String
    end

    let(:get_containers) { subject.get_containers }
    let(:expected_container_count) { subject.get_account_info["x-account-container-count"].to_i }
    it 'should respond to get_containers' do
      is_expected.to respond_to :get_containers
      put_container
      expect(expected_container_count).to be > 0
      expect { get_containers }.not_to raise_error
      expect(get_containers).to be_a Array
      expect(get_containers.length).to eq(expected_container_count)
    end

    let(:get_container_objects) { subject.get_container_objects(container_name) }
    let(:expected_object_count) { subject.get_container_meta(container_name)["x-container-object-count"].to_i }
    it 'should respond to get_container_objects' do
      is_expected.to respond_to :get_container_objects
      put_container
      put_object
      put_object_manifest
      expect(expected_object_count).to be > 0
      expect { get_container_objects }.not_to raise_error
      expect(get_container_objects).to be_a Array
      expect(get_container_objects.length).to eq(expected_object_count)
    end

    let(:get_account_info) { subject.get_account_info }
    it 'should respond to get_account_info' do
      is_expected.to respond_to :get_account_info
      expect { get_account_info }.not_to raise_error
      expect(get_account_info).to be
    end

    let(:register_keys) { subject.register_keys }
    it 'should respond to register_keys' do
      is_expected.to respond_to :register_keys
      expect { register_keys }.not_to raise_error
      expect(register_keys).to be_truthy
    end

    let(:put_container) { subject.put_container(container_name) }
    it 'should respond to put_container' do
      is_expected.to respond_to :put_container
      expect { put_container }.not_to raise_error
      expect(put_container).to be_truthy
    end

    let(:put_container_meta){
      resp = subject.put_container(container_name)
      HTTParty.get("#{subject.storage_url}/#{container_name}", headers:{"X-Auth-Token" => subject.auth_token})
    }
    it 'should set X-Container-Meta-Access-Control-Allow-Origin' do
      expect { put_container_meta }.not_to raise_error
      expect(put_container_meta.headers).to have_key 'x-container-meta-access-control-allow-origin'
      expect(put_container_meta.headers['x-container-meta-access-control-allow-origin']).to eq '*'
    end

    describe '.get_container_meta' do
      let(:get_container_meta) {
        subject.get_container_meta(container_name)
      }

      context 'before container exists' do
        it 'should return null' do
          r = nil
          expect {
            r = get_container_meta
          }.not_to raise_error
          expect(r).to be_nil
        end
      end

      context 'when container exists' do
        before do
          subject.put_container(container_name)
        end

        it 'should return null' do
          r = nil
          expect {
            r = get_container_meta
          }.not_to raise_error
          expect(r).not_to be_nil
        end
      end
    end

    let(:put_object) { subject.put_object(container_name, segment_name, object_body) }
    it 'should respond to put_object' do
      is_expected.to respond_to :put_object
      expect { put_object }.not_to raise_error
      expect(put_object).to be_truthy
    end

    let(:get_object_metadata) { subject.get_object_metadata(container_name, segment_name) }
    it 'should respond to get_object_metadata' do
      put_container
      put_object
      is_expected.to respond_to :get_object_metadata
      expect {
        resp = get_object_metadata
        expect(resp).to be
      }.not_to raise_error
    end

    let(:put_object_manifest) { subject.put_object_manifest(container_name, slo_name, manifest_hash) }
    it 'should respond to put_object_manifest' do
      is_expected.to respond_to :put_object_manifest
      expect { put_object_manifest }.not_to raise_error
      expect(put_object_manifest).to be_truthy
    end

    let(:put_object_manifest_content_type) {
      subject.put_object_manifest(container_name, slo_name, manifest_hash, content_type)
    }
    it 'should store the content_type on the manifest object as the content-type' do
      expect { put_object_manifest_content_type }.not_to raise_error
      expect(put_object_manifest_content_type).to be_truthy
      resp = subject.get_object_metadata(container_name, slo_name)
      expect(resp['content-type']).to eq(content_type)
    end

    let(:put_object_manifest_filename) {
      subject.put_object_manifest(container_name, slo_name, manifest_hash, nil, filename)
    }
    it 'should store the filename on the manifest object in the content-disposition' do
      expect { put_object_manifest_filename }.not_to raise_error
      expect(put_object_manifest_filename).to be_truthy
      resp = subject.get_object_metadata(container_name, slo_name)
      expect(resp['content-disposition']).to eq("attachment; filename=#{filename}")
    end

    let(:put_object_manifest_content_type_filename) {
      subject.put_object_manifest(container_name, slo_name, manifest_hash, content_type, filename)
    }
    it 'should store both the content_type and filename on the manifest object' do
      expect { put_object_manifest_content_type_filename }.not_to raise_error
      expect(put_object_manifest_content_type_filename).to be_truthy
      resp = subject.get_object_metadata(container_name, slo_name)
      expect(resp['content-type']).to eq(content_type)
      expect(resp['content-disposition']).to eq("attachment; filename=#{filename}")
    end

    let(:delete_object) { subject.delete_object(container_name, segment_name) }
    it 'should respond to delete_object' do
      put_container
      put_object
      is_expected.to respond_to :delete_object
      expect { delete_object }.not_to raise_error
      expect(delete_object).to be_truthy
    end

    let(:delete_object_manifest) { subject.delete_object_manifest(container_name, slo_name) }
    it 'should respond to delete_object_manifest' do
      put_container
      put_object
      put_object_manifest
      is_expected.to respond_to :delete_object_manifest
      expect { delete_object_manifest }.not_to raise_error
      expect(delete_object_manifest).to be_truthy
    end

    let(:delete_container) { subject.delete_container(container_name) }
    it 'should respond to delete_container' do
      is_expected.to respond_to :delete_container
      expect { delete_container }.not_to raise_error
      expect(delete_container).to be_truthy
    end
  end

  describe 'methods for building signed urls' do
    let(:expected_root_path) { "/#{subject.provider_version}/#{subject.name}" }

    it 'should respond to signed_url_duration' do
      is_expected.to respond_to :signed_url_duration
      expect(subject.signed_url_duration).to eq(300)
    end

    it 'should respond to root_path' do
      is_expected.to respond_to :root_path
      expect(subject.root_path).to eq(expected_root_path)
    end

    it 'should respond to digest' do
      is_expected.to respond_to :digest
      expect(subject.digest).to be_a OpenSSL::Digest
      expect(subject.digest.name).to eq('SHA1')
    end

    it 'should respond to build_signature' do
      is_expected.to respond_to :build_signature
      body = ['PUT', 1234, '/foo'].join('\n')
      expected_signature = OpenSSL::HMAC.hexdigest(subject.digest, subject.primary_key, body)
      expect(subject.build_signature(body, subject.primary_key)).to eq(expected_signature)
      expect(subject.build_signature(body)).to eq(expected_signature)
    end

    it 'should respond to build_signed_url' do
      is_expected.to respond_to :build_signed_url
    end
  end

  describe 'a signed url' do
    # build_signed_url parameters
    let(:http_verb) { 'PUT' }
    let(:sub_path) { Faker::Internet.slug }
    let(:expiry) { Faker::Number.number(10) }
    let(:filename) { 'File Name With Spaces.txt' }

    let(:signed_url) { subject.build_signed_url(http_verb, sub_path, expiry) }
    let(:parsed_url) { URI.parse(signed_url) }
    let(:decoded_query) { URI.decode_www_form(parsed_url.query) }
    let(:expected_path) { "#{subject.root_path}/#{sub_path}" }
    let(:expected_hmac_body) { [http_verb, expiry, expected_path].join("\n") }
    let(:expected_signature) { storage_provider.build_signature(expected_hmac_body) }

    it 'should return a valid url with query params' do
      expect(signed_url).to be_a String
      expect { parsed_url }.not_to raise_error
      expect(parsed_url.query).not_to be_empty
      expect { decoded_query }.not_to raise_error
      expect(decoded_query).to be_a Array
    end

    it 'should include the path in the url' do
      expect(URI.decode(parsed_url.path)).to eq expected_path
    end

    it 'should have temp_url_sig in query' do
      expect(decoded_query.assoc('temp_url_sig')).not_to be_nil
      expect(decoded_query.assoc('temp_url_sig').last).to eq(expected_signature)
    end

    it 'should have temp_url_expires in query' do
      expect(decoded_query.assoc('temp_url_expires')).not_to be_nil
      expect(decoded_query.assoc('temp_url_expires').last).to eq(expiry)
    end

    context 'with filename' do
      let(:signed_url) { subject.build_signed_url(http_verb, sub_path, expiry, filename) }

      it 'should return a valid url with query params' do
        expect(signed_url).to be_a String
        expect { parsed_url }.not_to raise_error
        expect(parsed_url.query).not_to be_empty
        expect { decoded_query }.not_to raise_error
        expect(decoded_query).to be_a Array
      end

      it 'should have filename in query' do
        expect(decoded_query.assoc('filename')).not_to be_nil
        expect(decoded_query.assoc('filename').last).to eq(filename)
      end
    end
  end

  describe 'validations' do
    it 'should require attributes' do
      is_expected.to validate_presence_of :name
      is_expected.to validate_presence_of :display_name
      is_expected.to validate_uniqueness_of :display_name
      is_expected.to validate_presence_of :description
      is_expected.to validate_presence_of :url_root
      is_expected.to validate_presence_of :provider_version
      is_expected.to validate_presence_of :auth_uri
      is_expected.to validate_presence_of :service_user
      is_expected.to validate_presence_of :service_pass
      is_expected.to validate_presence_of :primary_key
      is_expected.to validate_presence_of :secondary_key
      is_expected.to validate_presence_of :chunk_max_number
      is_expected.to validate_presence_of :chunk_max_size_bytes
    end

    context 'is_default' do
      let(:new_default_storage_provider) { FactoryBot.build(:swift_storage_provider, :default) }
      let(:new_not_default_storage_provider) { FactoryBot.build(:swift_storage_provider) }
      it 'should allow only one default storage_provider' do
        expect(subject.is_default?).to be_truthy
        expect(new_default_storage_provider).not_to be_valid
        expect(new_not_default_storage_provider).to be_valid
        subject.update(is_default: false)
        expect(new_default_storage_provider).to be_valid
        expect(new_not_default_storage_provider).to be_valid
      end
    end

    context 'is_deprecated' do
      let(:not_default_storage_provider) { FactoryBot.build(:swift_storage_provider) }
      it {
        is_expected.to be_valid
        expect(not_default_storage_provider).to be_valid

        subject.is_deprecated = true
        is_expected.not_to be_valid

        not_default_storage_provider.is_deprecated = true
        expect(not_default_storage_provider).to be_valid
      }
    end
  end

  describe '.default' do
    let(:default_storage_provider) { FactoryBot.create(:swift_storage_provider, :default) }
    let(:not_default_storage_provider) { FactoryBot.create(:swift_storage_provider, is_default: false) }
    subject { StorageProvider.default }

    it { expect(described_class).to respond_to(:default) }

    context 'without any storage_providers' do
      it {
        is_expected.to be_nil
      }
    end

    context 'with a default storage_provider' do
      before do
        expect(default_storage_provider).to be_persisted
        expect(not_default_storage_provider).to be_persisted
      end

      it {
        is_expected.to eq(default_storage_provider)
        is_expected.not_to eq(not_default_storage_provider)
      }
    end

    context 'without a default storage_provider' do
      before do
        expect(not_default_storage_provider).to be_persisted
      end

      it {
        is_expected.to be_nil
      }
    end
  end
end
