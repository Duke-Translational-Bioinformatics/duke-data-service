require 'rails_helper'

RSpec.describe ChunkedUpload, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'
  subject { FactoryBot.create(:chunked_upload, :with_chunks, storage_provider: mocked_storage_provider) }

  let(:unexpected_exception) { StorageProviderException.new('Unexpected') }

  it { is_expected.to be_an Upload }

  # Associations
  it { is_expected.to have_many(:chunks).with_foreign_key('upload_id') }

  # Callbacks
  it { is_expected.to callback(:initialize_storage).after(:create) }

  # Instance methods
  it 'should have a manifest method' do
    is_expected.to respond_to 'manifest'
    expect(subject.manifest).to be_a Array
    expect(subject.chunks).not_to be_empty
    expect(subject.manifest.count).to eq(subject.chunks.count)
    subject.chunks.reorder(:number).each do |chunk|
      chunk_manifest = {
        path: chunk.sub_path,
        etag: chunk.fingerprint_value,
        size_bytes: chunk.size
      }
      expect(subject.manifest[chunk.number - 1]).to eq chunk_manifest
    end
  end

  describe '#purge_storage' do
    let(:original_chunks_count) { subject.chunks.count }

    it { is_expected.to respond_to :purge_storage }

    context 'StorageProviderException' do
      it 'should raise the exception and not purge' do
        expect(subject.chunks).not_to be_empty
        subject.chunks.each do |chunk|
          expect(chunk).to receive(:purge_storage)
        end

        expect(mocked_storage_provider).to receive(:purge)
          .with(subject)
          .and_raise(unexpected_exception)

        expect {
          expect {
            subject.purge_storage
          }.to change{Chunk.count}.by(-original_chunks_count)
        }.to raise_error(unexpected_exception)

        subject.reload
        expect(subject.purged_on).to be_nil
        expect(subject.chunks.count).to eq 0
      end
    end

    context 'no StorageProviderException' do
      around(:each) do |example|
        travel_to(Time.now) do #freeze_time
          example.run
        end
      end
      it 'should purge successfully' do
        expect(subject.chunks).not_to be_empty
        subject.chunks.each do |chunk|
          expect(chunk).to receive(:purge_storage)
        end

        expect(mocked_storage_provider).to receive(:purge)
          .with(subject)

        purge_time = DateTime.now
        expect {
          expect {
            subject.purge_storage
          }.to change{Chunk.count}.by(-original_chunks_count)
        }.not_to raise_error

        subject.reload
        expect(subject.purged_on).to eq purge_time
        expect(subject.chunks.count).to eq(0)
      end
    end
  end #purge_storage

  it { is_expected.to respond_to :initialize_storage }
  describe '#initialize_storage' do
    subject { FactoryBot.create(:chunked_upload, storage_provider: mocked_storage_provider) }
    let(:mocked_storage_provider) { FactoryBot.create(:storage_provider, :default) }

    it 'enqueues a UploadStorageProviderInitializationJob' do
      expect {
        subject.initialize_storage
      }.to have_enqueued_job(UploadStorageProviderInitializationJob)
        .with(job_transaction: instance_of(JobTransaction), storage_provider: subject.storage_provider, upload: subject)
    end
  end

  it { is_expected.to respond_to :ready_for_chunks? }
  describe '#ready_for_chunks?' do
    subject { FactoryBot.create(:chunked_upload, storage_provider: mocked_storage_provider) }
    let(:mocked_storage_provider) { FactoryBot.create(:storage_provider, :default) }
    let(:upload_ready) { true }
    before(:example) do
      expect(mocked_storage_provider).to receive(:chunk_upload_ready?).with(subject) { upload_ready }
    end

    it { expect(subject.ready_for_chunks?).to eq true }

    context 'when upload is not ready' do
      let(:upload_ready) { false }
      it { expect(subject.ready_for_chunks?).to eq false }
    end
  end

  it { is_expected.to respond_to :check_readiness! }
  describe '#check_readiness!' do
    let(:readiness) { true }
    before(:example) do
      allow(subject).to receive(:ready_for_chunks?).and_return(readiness)
    end
    it { expect(subject.check_readiness!).to be_truthy }

    context 'when not ready' do
      let(:readiness) { false }
      it { expect { subject.check_readiness! }.to raise_error ConsistencyException, 'Upload is not ready' }
    end
  end

  it { is_expected.to respond_to :complete }
  describe '#complete' do
    let(:fingerprint_attributes) { FactoryBot.attributes_for(:fingerprint) }
    before { subject.fingerprints_attributes = [fingerprint_attributes] }

    it {
      expect(subject.completed_at).to be_nil
      expect {
        expect(subject.complete).to be_truthy
      }.to have_enqueued_job(UploadCompletionJob)
      subject.reload
      expect(subject.completed_at).not_to be_nil
    }
  end

  it { is_expected.to respond_to :complete_and_validate_integrity }
  describe '#complete_and_validate_integrity' do
    subject { FactoryBot.create(:chunked_upload, is_consistent: false, storage_provider: mocked_storage_provider) }

    context 'with valid reported size and chunk hashes' do
      it 'should set is_consistent to true, leave error_at and error_message null' do
        expect(mocked_storage_provider).to receive(:complete_chunked_upload)
          .with(subject)
        subject.complete_and_validate_integrity
        subject.reload
        expect(subject.is_consistent).to be_truthy
        expect(subject.error_at).to be_nil
        expect(subject.error_message).to be_nil
      end
    end #with valid

    context 'IntegrityException' do
      it 'should set is_consistent to true, set integrity_exception message as error_message, and set error_at' do
        expect(mocked_storage_provider).to receive(:complete_chunked_upload)
          .with(subject)
          .and_raise(IntegrityException)
        subject.complete_and_validate_integrity
        subject.reload
        expect(subject.is_consistent).to be_truthy
        expect(subject.error_at).not_to be_nil
        expect(subject.error_message).not_to be_nil
      end
    end #with reported size

    context 'StorageProvider Exception' do
      it 'should update completed_at, error_at and error_message and raise an IntegrityException' do
        expect(subject.is_consistent).not_to be_truthy
        expect(mocked_storage_provider).to receive(:complete_chunked_upload)
          .with(subject)
          .and_raise(unexpected_exception)
        expect {
          subject.complete_and_validate_integrity
        }.to raise_error(unexpected_exception)
        subject.reload
        expect(subject.is_consistent).not_to be_truthy
        expect(subject.error_at).to be_nil
        expect(subject.error_message).to be_nil
      end
    end
  end #complete_and_validate_integrity
end
