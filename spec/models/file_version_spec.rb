require 'rails_helper'

RSpec.describe FileVersion, type: :model do
  subject { file_version }
  let(:file_version) { FactoryGirl.create(:file_version) }
  let(:data_file) { file_version.data_file }
  let(:deleted_file_version) { FactoryGirl.create(:file_version, :deleted) }
  let(:uri_encoded_name) { URI.encode(subject.data_file.name) }
  let(:upload) { file_version.upload }
  let(:other_upload) { FactoryGirl.create(:upload, :completed) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let!(:kind_name) { 'file-version' }
  end
  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a graphed model', auto_create: true, logically_deleted: true

  describe 'associations' do
    it { is_expected.to belong_to(:data_file) }
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to have_many(:project_permissions).through(:data_file) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :upload_id }

    context 'when deletion_allowed? is true' do
      before { allow(subject).to receive(:deletion_allowed?).and_return(true) }
      it { is_expected.to allow_value(true).for(:is_deleted) }
      it { is_expected.to allow_value(false).for(:is_deleted) }
    end

    context 'when deletion_allowed? is false' do
      before { allow(subject).to receive(:deletion_allowed?).and_return(false) }
      it { is_expected.not_to allow_value(true).for(:is_deleted).with_message('The current file version cannot be deleted.') }
      it { is_expected.to allow_value(false).for(:is_deleted) }
    end

    context 'when #is_deleted=true' do
      subject { deleted_file_version }
      it { is_expected.not_to validate_presence_of(:upload_id) }
    end

    it 'should not allow upload_id to be changed' do
      should allow_value(upload).for(:upload)
      expect(subject).to be_valid
      should allow_value(upload.id).for(:upload_id)
      should_not allow_value(other_upload.id).for(:upload_id)
      should allow_value(upload.id).for(:upload_id)
      expect(subject).to be_valid
      should allow_value(other_upload).for(:upload)
      expect(subject).not_to be_valid
    end

    context 'when duplicating current_version' do
      before { expect(data_file.reload).to be_truthy }
      subject { data_file.current_file_version.dup }
      it { is_expected.not_to be_valid }
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

    describe '#next_version_number' do
      let(:data_file) { FactoryGirl.create(:data_file) }
      subject { data_file.file_versions.last }
      it { is_expected.to respond_to(:next_version_number) }

      context 'when file_version exists' do
        let(:expected_next_version_number) { subject.version_number + 1 }
        before { expect(subject).to be_persisted }
        it { expect(subject.next_version_number).to eq expected_next_version_number }

        context 'with versions for other files' do
          let!(:other_file_version) { FactoryGirl.create(:file_version) }
          it { expect(subject.next_version_number).to eq expected_next_version_number }
        end
      end
    end

    describe '#set_version_number' do
      subject { FactoryGirl.build(:file_version) }
      let!(:existing_file_version) { FactoryGirl.create(:file_version, data_file: subject.data_file) }
      it { is_expected.not_to be_persisted }
      it { is_expected.to respond_to(:set_version_number) }
      it { expect(subject.set_version_number).to eq subject.next_version_number }
      context 'when called' do
        before { subject.set_version_number }
        it { expect(subject.version_number).to eq subject.next_version_number }
      end
      context 'with persisted file_version' do
        subject { FactoryGirl.create(:file_version, version_number: 123) }
        let!(:original_version) { subject.version_number }
        before { is_expected.to be_persisted }
        it { expect(subject.set_version_number).to eq original_version }
        context 'when called' do
          before { subject.set_version_number }
          it { expect(subject.version_number).to eq original_version }
        end
      end
    end

    describe '#deletion_allowed?' do
      it { is_expected.to respond_to(:deletion_allowed?) }

      context 'when not current_file_version' do
        subject { data_file.file_versions.first }
        before { data_file.reload }
        it { is_expected.not_to eq data_file.current_file_version }
        it { expect(subject.deletion_allowed?).to be_truthy }
      end

      context 'when current_file_version' do
        before { data_file.reload }
        it { is_expected.to eq data_file.current_file_version }
        it { expect(subject.deletion_allowed?).to be_falsey }

        context 'with data_file.is_deleted true' do
          before { data_file.is_deleted = true }
          it { expect(subject.deletion_allowed?).to be_truthy }
        end
      end
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_version_number).before(:create) }
  end
end
