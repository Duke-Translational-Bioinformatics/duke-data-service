require 'rails_helper'

RSpec.describe FileVersion, type: :model do
  subject { file_version }
  let(:file_version) { FactoryBot.create(:file_version) }
  let(:data_file) { file_version.data_file }
  let(:deleted_file_version) { FactoryBot.create(:file_version, :deleted) }
  let(:uri_encoded_name) { URI.encode(subject.data_file.name) }
  let(:upload) { file_version.upload }
  let(:other_upload) { FactoryBot.create(:upload, :completed, :with_fingerprint) }

  include_context 'mock all Uploads StorageProvider'

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let(:expected_kind) { 'dds-file-version' }
    let(:kinded_class) { FileVersion }
    let(:serialized_kind) { true }
  end

  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a graphed node', logically_deleted: true
  it_behaves_like 'a job_transactionable model'

  context 'previous data_file version' do
    before do
      data_file.upload = other_upload
      expect(data_file.save).to be_truthy
      expect(subject.deletion_allowed?).to be_truthy
    end
    it_behaves_like 'a Restorable'
    it_behaves_like 'a Purgable'
  end

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

    context 'when purge_allowed? is true' do
      before {
        subject.update_column(:is_deleted, true)
        allow(subject).to receive(:purge_allowed?).and_return(true)
      }
      it { is_expected.to allow_value(true).for(:is_purged) }
      it { is_expected.to allow_value(false).for(:is_purged) }
    end

    context 'when purge_allowed? is false' do
      before {
        subject.update_column(:is_deleted, true)
        allow(subject).to receive(:purge_allowed?).and_return(false)
      }
      it { is_expected.not_to allow_value(true).for(:is_purged).with_message('The current file version cannot be purged.') }
      it { is_expected.to allow_value(false).for(:is_purged) }
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
      let(:data_file) { FactoryBot.create(:data_file) }
      subject { data_file.file_versions.last }
      it { is_expected.to respond_to(:next_version_number) }

      context 'when file_version exists' do
        let(:expected_next_version_number) { subject.version_number + 1 }
        before { expect(subject).to be_persisted }
        it { expect(subject.next_version_number).to eq expected_next_version_number }

        context 'with versions for other files' do
          let!(:other_file_version) { FactoryBot.create(:file_version) }
          it { expect(subject.next_version_number).to eq expected_next_version_number }
        end
      end
    end

    describe '#set_version_number' do
      subject { FactoryBot.build(:file_version) }
      let!(:existing_file_version) { FactoryBot.create(:file_version, data_file: subject.data_file) }
      it { is_expected.not_to be_persisted }
      it { is_expected.to respond_to(:set_version_number) }
      it { expect(subject.set_version_number).to eq subject.next_version_number }
      context 'when called' do
        before { subject.set_version_number }
        it { expect(subject.version_number).to eq subject.next_version_number }
      end
      context 'with persisted file_version' do
        subject { FactoryBot.create(:file_version, version_number: 123) }
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


    describe '#purge_allowed?' do
      it { is_expected.to respond_to(:purge_allowed?) }

      context 'when not current_file_version' do
        subject { data_file.file_versions.first }
        before { data_file.reload }
        it { is_expected.not_to eq data_file.current_file_version }
        it { expect(subject.purge_allowed?).to be_truthy }
      end

      context 'when current_file_version' do
        before { data_file.reload }
        it { is_expected.to eq data_file.current_file_version }
        it { expect(subject.purge_allowed?).to be_falsey }

        context 'with data_file.is_purged true' do
          before { data_file.is_purged = true }
          it { expect(subject.purge_allowed?).to be_truthy }
        end
      end
    end

    describe '#manage_purge_and_restore' do
      it { is_expected.to respond_to :manage_purge_and_restore }

      context 'recently_purged' do
        let(:job_transaction) {
          subject.create_transaction('testing')
          UploadStorageRemovalJob.initialize_job(subject)
        }

        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          subject.update_column(:is_deleted, true)
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end

        it {
          expect(subject.is_deleted?).to be_truthy
          subject.is_purged = true
          yield_called = false
          expect(UploadStorageRemovalJob).to receive(:initialize_job)
            .with(subject).and_return(job_transaction)
          expect(UploadStorageRemovalJob).to receive(:perform_later).with(job_transaction, subject.upload.id)
          subject.manage_purge_and_restore do
            yield_called = true
          end
          expect(yield_called).to be_truthy
        }
      end

      context 'recently_restored' do
        context 'with deleted data_file' do
          before do
            FileVersion.skip_callback(:update, :around, :manage_purge_and_restore)
            subject.update_column(:is_deleted, true)
            subject.data_file.update_column(:is_deleted, true)
          end

          after do
            FileVersion.set_callback(:update, :around, :manage_purge_and_restore)
          end
          it {
            expect(subject.is_deleted?).to be_truthy
            expect(subject.is_purged?).to be_falsey
            expect(subject.data_file.is_deleted?).to be_truthy
            expect(subject.data_file).to receive(:update).with(is_deleted: false)
            subject.is_deleted = false
            yield_called = false
            subject.manage_purge_and_restore do
              yield_called = true
            end
            expect(yield_called).to be_truthy
          }
        end

        context 'with non-deleted data_file' do
          before do
            subject.update_column(:is_deleted, true)
          end
          it {
            expect(subject.is_deleted?).to be_truthy
            expect(subject.is_purged?).to be_falsey
            expect(subject.data_file.is_deleted?).to be_falsey
            expect(subject.data_file).not_to receive(:update)
            subject.is_deleted = false
            yield_called = false
            subject.manage_purge_and_restore do
              yield_called = true
            end
            expect(yield_called).to be_truthy
          }
        end
      end
    end
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_version_number).before(:create) }
    it {
      is_expected.to callback(:manage_purge_and_restore).around(:update)
    }
  end

  describe '#purge' do
    it {
      expect {
        begin
          subject.purge
        rescue UnPurgableException => e
          expect(e.message).to eq(subject.kind)
          raise e
        end
      }.to raise_error(UnPurgableException)
    }
  end
end
