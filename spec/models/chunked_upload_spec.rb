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
end
