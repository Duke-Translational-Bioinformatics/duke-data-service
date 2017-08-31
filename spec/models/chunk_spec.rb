require 'rails_helper'

RSpec.describe Chunk, type: :model do
  subject { FactoryGirl.create(:chunk) }
  let(:storage_provider) { subject.storage_provider }

  let(:expected_object_path) { [subject.upload_id, subject.number].join('/')}
  let(:expected_sub_path) { [subject.storage_container, expected_object_path].join('/')}
  let(:expected_expiry) { subject.updated_at.to_i + storage_provider.signed_url_duration }
  let(:expected_url) { storage_provider.build_signed_url(subject.http_verb, expected_sub_path, expected_expiry) }
  let(:is_logically_deleted) { false }
  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to have_one(:storage_provider).through(:upload) }
    it { is_expected.to have_one(:project).through(:upload) }
    it { is_expected.to have_many(:project_permissions).through(:upload) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:upload_id) }
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:fingerprint_value) }
    it { is_expected.to validate_presence_of(:fingerprint_algorithm) }
    it { is_expected.to validate_uniqueness_of(:number).scoped_to(:upload_id).case_insensitive }
  end

  describe 'instances' do
    it 'should delegate #storage_container to upload' do
      is_expected.to delegate_method(:storage_container).to(:upload)
      expect(subject.storage_container).to eq(subject.upload.storage_container)
    end

    it 'should implement #http_verb' do
      is_expected.to respond_to :http_verb
      expect(subject.http_verb).to eq 'PUT'
    end

    it 'should implement #host' do
      is_expected.to respond_to :host
      expect(subject.host).to eq storage_provider.url_root
    end

    it 'should implement #http_headers' do
      is_expected.to respond_to :http_headers
      expect(subject.http_headers).to eq []
    end

    it 'should implement #object_path' do
      is_expected.to respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end
  end

  it 'should implement #url' do
    is_expected.to respond_to :url
    expect(subject.url).to eq expected_url
  end

  context '#purge_storage' do
    it { is_expected.to respond_to :purge_storage }

    context 'called', :vcr do
      subject {
        FactoryGirl.create(:chunk, :swift, size: chunk_data.length)
      }
      let(:storage_provider) { subject.storage_provider }
      let(:chunk_data) { 'some random chunk' }
      before do
        storage_provider.register_keys
        storage_provider.put_container(subject.storage_container)
        storage_provider.put_object(
          subject.storage_container,
          subject.object_path,
          chunk_data
        )
      end
      after do
        begin
          storage_provider.delete_object(subject.storage_container, subject.object_path)
        rescue
          #ignore
        end
      end
      it {
        resp = HTTParty.get(
          "#{storage_provider.storage_url}/#{subject.storage_container}/#{subject.object_path}",
          headers: storage_provider.auth_header
        )
        expect(resp.response.code.to_i).to eq(200)
        expect(resp.body).to eq(chunk_data)
        subject.purge_storage
        resp = HTTParty.get(
          "#{storage_provider.storage_url}/#{subject.storage_container}/#{subject.object_path}",
          headers: storage_provider.auth_header
        )
        expect(resp.response.code.to_i).to eq(404)
      }
    end
  end
end
