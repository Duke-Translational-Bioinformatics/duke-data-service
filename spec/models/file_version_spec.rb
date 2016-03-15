require 'rails_helper'

RSpec.describe FileVersion, type: :model do
  subject { file_version }
  let(:file_version) { FactoryGirl.create(:file_version) }
  let(:deleted_file_version) { FactoryGirl.create(:file_version, :deleted) }
  let(:uri_encoded_name) { URI.encode(subject.data_file.name) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let!(:kind_name) { 'file-version' }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:data_file) }
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to belong_to(:creator) }
  end

  describe 'validations' do
    let(:completed_upload) { FactoryGirl.create(:upload, :completed, creator: subject.creator) }
    let(:incomplete_upload) { FactoryGirl.create(:upload, creator: subject.creator) }
    let(:upload_with_error) { FactoryGirl.create(:upload, :with_error, creator: subject.creator) }
    let(:not_creator_of_upload) { FactoryGirl.create(:upload, :completed) }

    it 'should have a upload_id' do
      should validate_presence_of(:upload_id)
    end

    it 'should require upload has no error' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(upload_with_error.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      should_not allow_value(upload_with_error).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('cannot have an error')
    end

    it 'should require a completed upload' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(incomplete_upload.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(incomplete_upload).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('must be completed successfully')
    end

    it 'should require creator equal upload.creator' do
      should allow_value(completed_upload.id).for(:upload_id)
      should_not allow_value(not_creator_of_upload.id).for(:upload_id)
      should allow_value(completed_upload).for(:upload)
      should_not allow_value(not_creator_of_upload).for(:upload)
      expect(subject.valid?).to be_falsey
      expect(subject.errors.keys).to include(:upload)
      expect(subject.errors[:upload]).to include('created by another user')
    end

    it 'should require a creator_id' do
      should validate_presence_of :creator_id
    end

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    context 'when #is_deleted=true' do
      subject { deleted_file_version }
      it { is_expected.not_to validate_presence_of(:upload_id) }
      it { is_expected.not_to validate_presence_of(:creator_id) }
    end
  end

  describe 'instance methods' do
    it { should delegate_method(:name).to(:data_file) }
    it { should delegate_method(:http_verb).to(:upload) }
    it { should delegate_method(:host).to(:upload).as(:url_root) }
    it { should delegate_method(:url).to(:upload).as(:temporary_url) }

    describe '#url' do
      it { expect(subject.url).to include uri_encoded_name }
    end
  end
end
