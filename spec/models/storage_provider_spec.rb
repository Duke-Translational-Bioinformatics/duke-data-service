require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe StorageProvider, type: :model do
  let(:chunk) { FactoryGirl.create(:chunk) }
  let(:storage_provider) { FactoryGirl.create(:storage_provider) }
  let(:swift_storage_provider) { FactoryGirl.create(:storage_provider, :swift) }

  describe "swift access method", :if => false && ENV['SWIFT_USER'] do
    # these tests only run if the SWIFT ENV variables are set
    # to allow it to communicate with a SWIFT backend
    before(:all) do
      @subject = FactoryGirl.create(:storage_provider, :swift_env)
      @auth_resp = HTTParty.get(
          "#{ENV['SWIFT_URL_ROOT']}#{ENV['SWIFT_AUTH_URI']}",
          headers: {
            'X-Auth-User' => ENV['SWIFT_USER'],
            'X-Auth-Key' => ENV['SWIFT_PASS']})
      @project = FactoryGirl.create(:project)
      @existing_upload = FactoryGirl.create(:upload,
        project_id: @project.id,
        storage_provider_id: @subject.id)
      HTTParty.put(
        "#{@auth_resp['x-storage-url']}/#{@project.id}",
        headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
    end

    after(:all) do
      resp = HTTParty.get(
        "#{@auth_resp['x-storage-url']}/#{@project.id}",
        headers:{"X-Auth-Token" => @auth_resp['x-auth-token']}
      )
      if resp.headers['x-container-object-count'].to_i > 0
        resp.body.split("\n").each do |obj|
          resp = HTTParty.delete(
            "#{@auth_resp['x-storage-url']}/#{@project.id}/#{obj}",
            headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        end
        User.destroy_all
      end

      HTTParty.delete(
        "#{@auth_resp['x-storage-url']}/#{@project.id}",
        headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})

      HTTParty.post(
        @auth_resp['x-storage-url'],
          headers:{
            "X-Auth-Token" => @auth_resp['x-auth-token'],
            'X-Account-Meta-Temp-URL-Key' => @subject.primary_key,
            'X-Account-Meta-Temp-URL-Key-2' => @subject.secondary_key})
    end

    describe "register_keys" do
      it 'should register the primary and secondary key with the swift account' do
        unexpected_key = 'unexpected'
        expect(@subject).to respond_to('register_keys')
        resp = HTTParty.get(@auth_resp['x-storage-url'], headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        if resp.headers['x-account-meta-temp-url-key']
          #temporarily unset them
          HTTParty.post(
            @auth_resp['x-storage-url'],
              headers:{
                "X-Auth-Token" => @auth_resp['x-auth-token'],
                'X-Account-Meta-Temp-URL-Key' => unexpected_key,
                'X-Account-Meta-Temp-URL-Key-2' => unexpected_key})
        end
        @subject.register_keys
        resp = HTTParty.get(@auth_resp['x-storage-url'], headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        expect(resp.headers['x-account-meta-temp-url-key']).to eq(@subject.primary_key)
        expect(resp.headers['x-account-meta-temp-url-key-2']).to eq(@subject.secondary_key)
      end
    end

    describe "get_signed_url" do
      before(:all) do
        @new_upload = FactoryGirl.create(:upload,
          project_id: @project.id,
          storage_provider_id: @subject.id)
        @new_chunk = FactoryGirl.create(:chunk,
          upload_id: @new_upload.id)
        @existingobject = Faker::Lorem.characters(100)

        HTTParty.put(
          "#{@auth_resp['x-storage-url']}/#{@project.id}/#{@existing_upload.id}",
           body: @existingobject,
           headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
      end

      it 'should take an upload and return a signed tempoary url to GET the upload object' do
        url = @existing_upload.temporary_url
        expect(url).to match(['',
          @subject.provider_version,
          @subject.name,
          @project.id,
          @existing_upload.id
        ].join('/'))

        temp_url = "#{@subject.url_root}#{url}"
        resp = HTTParty.get("#{temp_url}")
        expect(resp.response.code.to_i).to eq(200)
        expect(resp.body).to eq(@existingobject)
      end

      it 'should take a chunk and return a signed tempoary url to PUT data for the chunk object' do
        new_data = Faker::Lorem.characters(100)
        url = @new_chunk.url
        expect(url).to match(['',
          @subject.provider_version,
          @subject.name,
          @project.id,
          @new_upload.id,
          @new_chunk.number
        ].join('/'))
        resp = HTTParty.put("#{@subject.url_root}/#{url}", body: new_data)
        expect(resp.response.code.to_i).to eq(201)
        resp = HTTParty.get(
            "#{@auth_resp['x-storage-url']}/#{@project.id}/#{@new_upload.id}/#{@new_chunk.number}",
            headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        expect(resp.body).to eq(new_data)
      end
    end

    describe "create_slo_manifest" do
      before(:all) do
        @chunk_data = []
        @chunks = []
        10.times do |i|
          chunk_number = i + 1
          chunk_data = Faker::Lorem.characters(100)
          @chunk_data << chunk_data
          chunk = FactoryGirl.create(:chunk,
            upload_id: @existing_upload.id,
            size: chunk_data.length,
            fingerprint_value: Digest::MD5.hexdigest(chunk_data),
            number: chunk_number
           )
           HTTParty.put(
             "#{@auth_resp['x-storage-url']}/#{chunk.upload.project.id}/#{chunk.upload.id}/#{chunk.number}",
             body: chunk_data,
             headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
           @chunks << chunk
        end
      end

      it 'should take an upload, and create a manifest file for each chunk, then upload the manifest as an slo to the upload' do
        expect(@subject).to respond_to('create_slo_manifest')
        HTTParty.delete(
          "#{@auth_resp['x-storage-url']}/#{@project.id}/#{@existing_upload.id}",
          headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        @subject.create_slo_manifest(@existing_upload)
        resp = HTTParty.get(
          "#{@auth_resp['x-storage-url']}/#{@project.id}/#{@existing_upload.id}",
          headers:{"X-Auth-Token" => @auth_resp['x-auth-token']})
        expect(resp.response.code.to_i).to eq(200)
        expect(resp.body).to eq(@chunk_data.join(''))
      end
    end
  end

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
      expect(get_account_info).to be_truthy
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
      should validate_presence_of :url_root
      should validate_presence_of :provider_version
      should validate_presence_of :auth_uri
      should validate_presence_of :service_user
      should validate_presence_of :service_pass
      should validate_presence_of :primary_key
      should validate_presence_of :secondary_key
    end
  end

  describe 'serialization' do
  end
end
