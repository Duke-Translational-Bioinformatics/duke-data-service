require 'rails_helper'

RSpec.describe Chunk, type: :model do
  subject { FactoryBot.create(:chunk, :swift) }
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
    it {
      is_expected.to validate_numericality_of(:size)
        .is_less_than(subject.chunk_max_size_bytes)
    }
    it { is_expected.to validate_presence_of(:fingerprint_value) }
    it { is_expected.to validate_presence_of(:fingerprint_algorithm) }
    it { is_expected.to validate_uniqueness_of(:number).scoped_to(:upload_id).case_insensitive }

    describe 'upload_chunk_maximum' do
      let(:storage_provider) { FactoryBot.create(:storage_provider, chunk_max_number: 1) }
      context '< storage_provider.chunk_max_number' do
        let(:upload) { FactoryBot.create(:upload, storage_provider: storage_provider) }
        subject { FactoryBot.build(:chunk, upload: upload) }
        it { is_expected.to be_valid }
      end

      context '>= storage_provider.chunk_max_number' do
        let(:upload) { FactoryBot.create(:upload, :with_chunks, storage_provider: storage_provider) }
        let(:expected_validation_message) { "maximum upload chunks exceeded." }
        subject { FactoryBot.build(:chunk, upload: upload, number: 2) }

        it {
          is_expected.not_to be_valid
          expect(subject.errors.messages[:base]).to include expected_validation_message
        }
      end
    end
  end

  describe 'instance methods' do
    it 'should delegate #project_id and #storage_container to upload' do
      is_expected.to delegate_method(:project_id).to(:upload)
      expect(subject.project_id).to eq(subject.upload.project_id)
      is_expected.to delegate_method(:storage_container).to(:upload)
      expect(subject.storage_container).to eq(subject.upload.storage_container)
    end

    it { is_expected.to delegate_method(:chunk_max_size_bytes).to(:storage_provider) }
    it { is_expected.to delegate_method(:minimum_chunk_size).to(:upload) }

    it 'is_expected.to have a http_verb method' do
      is_expected.to respond_to :http_verb
      expect(subject.http_verb).to eq 'PUT'
    end

    it 'is_expected.to have a host method' do
      is_expected.to respond_to :host
      expect(subject.host).to eq storage_provider.url_root
    end

    it 'is_expected.to have a http_headers method' do
      is_expected.to respond_to :http_headers
      expect(subject.http_headers).to eq []
    end

    it 'is_expected.to have an object_path method' do
      is_expected.to respond_to :object_path
      expect(subject.object_path).to eq(expected_object_path)
    end
  end

  it 'is_expected.to have a url method' do
    is_expected.to respond_to :url
    expect(subject.url).to eq expected_url
  end

  context '#purge_storage', :vcr do
    it { is_expected.to respond_to :purge_storage }

    context 'called' do
      subject {
        FactoryBot.create(:chunk, :swift, size: chunk_data.length, number: 1)
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

      context 'StorageProviderException' do
        context 'Not Found' do
          it {
            expect {
              subject.storage_provider.delete_object(subject.storage_container, subject.object_path)
            }.not_to raise_error

            resp = HTTParty.get(
              "#{storage_provider.storage_url}/#{subject.storage_container}/#{subject.object_path}",
              headers: storage_provider.auth_header
            )
            expect(resp.response.code.to_i).to eq(404)

            expect {
              subject.purge_storage
            }.not_to raise_error
          }
        end

        context 'Other Exception' do
          let(:fake_storage_provider) { FactoryBot.create(:storage_provider) }
          it {
            #create authentication failure
            original_auth_header = storage_provider.auth_header
            original_storage_url = storage_provider.storage_url
            expect(
              storage_provider.update(
                service_user: fake_storage_provider.service_user
              )
            ).to be_truthy

            resp = HTTParty.get(
              "#{original_storage_url}/#{subject.storage_container}/#{subject.object_path}",
              headers: original_auth_header
            )
            expect(resp.response.code.to_i).to eq(200)
            expect(resp.body).to eq(chunk_data)

            storage_provider.remove_instance_variable(:'@auth_uri_resp')
            expect {
              subject.purge_storage
            }.to raise_error(StorageProviderException)

            resp = HTTParty.get(
              "#{original_storage_url}/#{subject.storage_container}/#{subject.object_path}",
              headers: original_auth_header
            )
            expect(resp.response.code.to_i).to eq(200)
            expect(resp.body).to eq(chunk_data)
          }
        end
      end

      context 'No StorageProviderException' do
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

  describe '#total_chunks' do
    it { is_expected.to respond_to :total_chunks }
    it { expect(subject.total_chunks).to eq(subject.upload.chunks.count ) }
  end
end
