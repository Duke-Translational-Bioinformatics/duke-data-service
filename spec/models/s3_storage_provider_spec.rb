require 'rails_helper'

RSpec.describe S3StorageProvider, type: :model do
  subject { FactoryBot.build(:s3_storage_provider) }
  let(:project) { stub_model(Project, id: SecureRandom.uuid) }
  let(:upload) { FactoryBot.create(:upload, :skip_validation) }
  let(:chunk) { FactoryBot.create(:chunk, :skip_validation, upload: upload) }

  it_behaves_like 'A StorageProvider implementation'

  describe '#configure' do
    it { expect(subject.configure).to eq true }
  end

  # S3 Interface
  describe '#client' do
    it { is_expected.to respond_to(:client).with(0).arguments }
  end

  describe '#list_buckets' do
    it { is_expected.to respond_to(:list_buckets).with(0).arguments }
  end

  describe '#create_bucket' do
    it { is_expected.not_to respond_to(:create_bucket).with(0).arguments }
    it { is_expected.to respond_to(:create_bucket).with(1).argument }
  end

  describe '#create_multipart_upload' do
    it { is_expected.not_to respond_to(:create_multipart_upload).with(0..1).arguments }
    it { is_expected.to respond_to(:create_multipart_upload).with(2).arguments }
  end

  describe '#complete_multipart_upload' do
    it { is_expected.not_to respond_to(:complete_multipart_upload).with(0..1).arguments }
    it { is_expected.not_to respond_to(:complete_multipart_upload).with(2).arguments }
    it { is_expected.to respond_to(:complete_multipart_upload).with(2).arguments.and_keywords(:upload_id, :parts) }
  end

  describe '#presigned_url' do
    it { is_expected.not_to respond_to(:presigned_url).with(0).arguments }
    it { is_expected.not_to respond_to(:presigned_url).with(1).argument }
    it { is_expected.to respond_to(:presigned_url).with(1).argument.and_keywords(:bucket, :object_key) }
    it { is_expected.to respond_to(:presigned_url).with(1).argument.and_keywords(:bucket, :object_key, :upload_id, :part_number, :content_length) }
  end
end
