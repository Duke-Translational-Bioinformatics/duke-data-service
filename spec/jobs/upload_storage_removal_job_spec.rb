require 'rails_helper'

RSpec.describe UploadStorageRemovalJob, type: :job do
  include_context 'mock all Uploads StorageProvider'
  let(:upload) { FactoryBot.create(:upload) }
  let(:job_transaction) { described_class.initialize_job(upload) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }

  it { expect(described_class.should_be_registered_worker?).to be_truthy }

  before do
    expect(upload).to be_persisted
  end

  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}upload_storage_removal") }
  it {
    expect {
      described_class.perform_now
    }.to raise_error(ArgumentError)
    expect {
      described_class.perform_now(job_transaction)
    }.to raise_error(ArgumentError)
  }

  context 'perform_now' do
    include_context 'tracking job', :job_transaction
    it 'should purge_storage of the upload' do
      expect(Upload).to receive(:find).with(upload.id).and_return(upload)
      expect(upload).to receive(:purge_storage).and_return(true)
      described_class.perform_now(job_transaction, upload.id)
    end
  end
end
