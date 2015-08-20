require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Chunk, type: :model do
  #let(:project) { FactoryGirl.create(:project)}
  #let(:storage_provider) { FactoryGirl.create(:storage_provider)}
  #let(:upload) { FactoryGirl.create(:upload, project_id: project.id, storage_provider_id: storage_provider.id)}
  #subject { FactoryGirl.create(:chunk, upload_id: upload.id) }
  subject { FactoryGirl.create(:chunk) }
  let(:storage_provider) { subject.storage_provider }

  describe 'associations' do
    it 'should belong_to an upload' do
      should belong_to :upload
    end
    it 'should have_one storage_provider via upload' do
      should have_one(:storage_provider).through(:upload)
    end
  end

  describe 'validations' do
    it 'should require attributes' do
      should validate_presence_of :upload_id
      should validate_presence_of :number
      should validate_presence_of :size
      should validate_presence_of :fingerprint_value
      should validate_presence_of :fingerprint_algorithm
    end
  end

  describe 'instance methods' do
    it 'should delegate project_id to upload' do
      should delegate_method(:project_id).to(:upload)
      expect(subject.project_id).to eq(subject.upload.project_id)
    end

    it 'should have a http_verb method' do
      should respond_to :http_verb
      expect(subject.http_verb).to eq 'PUT'
    end

    it 'should have a host method' do
      should respond_to :host
      #expect(subject.host).to eq storage_provider.url_root
    end

    it 'should have a http_headers method' do
      should respond_to :http_headers
      expect(subject.http_headers).to eq []
    end

    it 'should have a url method' do
      should respond_to :url
      expect(subject.url).not_to be_empty
    end
  end

  let(:expected_path) { [storage_provider.root_path, subject.project_id, subject.upload_id, subject.number].join('/')}
  let(:expected_expiry) { subject.updated_at.to_i + storage_provider.chunk_duration }
  let(:expected_hmac_body) { [subject.http_verb, expected_expiry, expected_path].join("\n") }
  let(:expected_signature) { storage_provider.build_signature(expected_hmac_body) }

  describe 'methods used to build a signed url' do
    it 'should have a path method' do
      should respond_to :path
      expect(subject.path).to eq(expected_path)
    end

    it 'should have an expiry method' do
      should respond_to :expiry
      expect(subject.expiry).to eq(expected_expiry)
    end

    it 'should have an hmac_body method' do
      should respond_to :hmac_body
      expect(subject.hmac_body).to eq(expected_hmac_body)
    end

    it 'should have an signature method' do
      should respond_to :signature
      expect(subject.signature).to eq(expected_signature)
    end
  end
  
  describe 'a signed url' do
    let(:signed_url) { subject.url }
    let(:parsed_url) { URI.parse(signed_url) }
    let(:decoded_query) { URI.decode_www_form(parsed_url.query) }

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
      expect(decoded_query.assoc('temp_url_expires').last.to_i).to eq(expected_expiry)
    end
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = ChunkSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('http_verb')
      expect(parsed_json).to have_key('host')
      expect(parsed_json).to have_key('url')
      expect(parsed_json).to have_key('http_headers')
      expect(parsed_json['http_verb']).to eq(subject.http_verb)
      expect(parsed_json['host']).to eq(subject.host)
      expect(parsed_json['http_headers']).to eq(subject.http_headers)
      expect(parsed_json['url']).to eq(subject.url)
    end
  end
end
