require 'rails_helper'

RSpec.describe UploadStorageProviderInitializationJob, type: :job do
  include_context 'mocked StorageProvider'
  include_context 'mocked StorageProvider Interface'

  let(:upload) { FactoryBot.create(:upload, storage_provider: mocked_storage_provider) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  let(:job_transaction) { described_class.initialize_job(upload) }

  it { expect(described_class.should_be_registered_worker?).to be_truthy }
  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}upload_storage_provider_initialization") }

  it { expect { described_class.perform_now }.to raise_error(ArgumentError, "missing keywords: job_transaction, storage_provider, upload") }

  context 'perform_now' do
    include_context 'tracking job', :job_transaction
    it 'calls storage_provider#initialize_chunked_upload with upload' do
      expect(mocked_storage_provider).to receive(:initialize_chunked_upload)
        .with(upload)
      described_class.perform_now(
        job_transaction: job_transaction,
        storage_provider: mocked_storage_provider,
        upload: upload
      )
    end
  end
end
