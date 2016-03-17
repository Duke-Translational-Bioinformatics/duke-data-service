require 'rails_helper'

RSpec.describe Chunk, type: :model do
  subject { FactoryGirl.create(:chunk) }
  let(:storage_provider) { subject.storage_provider }

  let(:expected_object_path) { [subject.upload_id, subject.number].join('/')}
  let(:expected_sub_path) { [subject.project_id, expected_object_path].join('/')}
  let(:expected_expiry) { subject.updated_at.to_i + storage_provider.signed_url_duration }
  let(:expected_url) { storage_provider.build_signed_url(subject.http_verb, expected_sub_path, expected_expiry) }
  let(:is_logically_deleted) { false }
  it_behaves_like 'an audited model'

  describe 'associations' do
    it 'should belong_to an upload' do
      should belong_to :upload
    end
    it 'should have_one storage_provider via upload' do
      should have_one(:storage_provider).through(:upload)
    end
    it 'should have one project via upload' do
      should have_one(:project).through(:upload)
    end
    it 'should have many project permissions' do
      should have_many(:project_permissions).through(:upload)
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
      expect(subject.host).to eq storage_provider.url_root
    end

    it 'should have a http_headers method' do
      should respond_to :http_headers
      expect(subject.http_headers).to eq []
    end

    it 'should have an object_path method' do
      should respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end
  end

  it 'should have a url method' do
    should respond_to :url
    expect(subject.url).to eq expected_url
  end
end
