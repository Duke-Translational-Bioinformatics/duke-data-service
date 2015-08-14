require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Chunk, type: :model do
  let(:project) { FactoryGirl.create(:project)}
  let(:storage_provider) { FactoryGirl.create(:storage_provider)}
  let(:upload) { FactoryGirl.create(:upload, project_id: project.id, storage_provider_id: storage_provider.id)}
  subject { FactoryGirl.create(:chunk, upload_id: upload.id) }

  describe 'associations' do
    it 'should belong_to an upload' do
      should belong_to :upload
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
    it 'should have a http_verb method' do
      should respond_to :http_verb
      expect(subject.http_verb).to eq 'PUT'
    end

    it 'should have a host method' do
      should respond_to :host
      expect(subject.host).to eq storage_provider.url_root
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
