require 'rails_helper'

RSpec.describe StorageProvider, type: :model do
  let(:chunk) { FactoryGirl.create(:chunk) }
  let(:storage_provider) { FactoryGirl.create(:storage_provider) }
  let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
  subject { storage_provider }

  describe 'methods that call swift api', :vcr do
    subject { swift_storage_provider }
    let(:container_name) { 'the_container' }
    let(:object_name) { 'the_object' }
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

    it 'should respond to storage_url' do
      is_expected.to respond_to :storage_url
      expect { subject.storage_url }.not_to raise_error
      expect(subject.storage_url).to be_a String
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

    let(:put_object_manifest) { subject.put_object_manifest(container_name, object_name, manifest_hash) }
    it 'should respond to put_object_manifest' do
      is_expected.to respond_to :put_object_manifest
      expect { put_object_manifest }.not_to raise_error
      expect(put_object_manifest).to be_truthy
    end

    let(:delete_object) { subject.delete_object(container_name, object_name) }
    it 'should respond to delete_object' do
      is_expected.to respond_to :delete_object
      expect { delete_object }.not_to raise_error
      expect(delete_object).to be_truthy
    end

    let(:delete_container) { subject.delete_container(container_name) }
    it 'should respond to delete_container' do
      is_expected.to respond_to :delete_container
      expect { delete_container }.not_to raise_error
      expect(delete_container).to be_truthy
    end
  end

  describe 'methods for building signed urls' do
    subject { storage_provider }
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
    subject { storage_provider }

    # build_signed_url parameters
    let(:http_verb) { 'PUT' }
    let(:sub_path) { Faker::Internet.slug }
    let(:expiry) { Faker::Number.number(10) }

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
  end

  describe 'validations' do
    it 'should require attributes' do
      should validate_presence_of :name
      should validate_presence_of :display_name
      should validate_uniqueness_of :display_name
      should validate_presence_of :description
      should validate_presence_of :url_root
      should validate_presence_of :provider_version
      should validate_presence_of :auth_uri
      should validate_presence_of :service_user
      should validate_presence_of :service_pass
      should validate_presence_of :primary_key
      should validate_presence_of :secondary_key
    end
  end
end
