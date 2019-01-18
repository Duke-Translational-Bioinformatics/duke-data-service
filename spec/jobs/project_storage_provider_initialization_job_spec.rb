require 'rails_helper'

RSpec.describe ProjectStorageProviderInitializationJob, type: :job do
  include_context 'mocked StorageProvider'

  let(:mocked_storage_provider) { FactoryBot.create(:storage_provider, :default) }
  let(:project) { FactoryBot.create(:project, :inconsistent) }
  let(:project_storage_provider) { FactoryBot.create(:project_storage_provider, project: project, storage_provider: mocked_storage_provider) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  let(:job_transaction) { described_class.initialize_job(project) }

  it { expect(described_class.should_be_registered_worker?).to be_truthy }
  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}project_storage_provider_initialization") }

  it { expect { described_class.perform_now }.to raise_error(ArgumentError, "missing keywords: job_transaction, project_storage_provider") }

  context 'perform_now' do
    before(:example) do
      allow_any_instance_of(Project).to receive(:initialize_storage)
      allow_any_instance_of(ProjectStorageProvider).to receive(:initialize_storage)
      expect(mocked_storage_provider).to receive(:initialize_project)
        .with(project) { initialize_project_response }
    end
    let(:initialize_project_response) { true }
    let(:call_perform_now) {
      described_class.perform_now(
        job_transaction: job_transaction,
        project_storage_provider: project_storage_provider
      )
    }
    context 'with StorageProvider#initialize_project success' do
      include_context 'tracking job', :job_transaction
      it 'sets project#is_consistent to true' do
        expect(call_perform_now).to be_truthy
        project_storage_provider.reload
        expect(project_storage_provider).to be_is_initialized
      end
    end

    context 'when StorageProvider#initialize_project raises StorageProviderException' do
      include_context 'tracking failed job', :job_transaction
      let(:initialize_project_response) { raise(StorageProviderException, 'boom!') }

      it 'raises the exception and project#is_consistent remains false' do
        expect(described_class).not_to receive(:complete_job)
        expect { call_perform_now }.to raise_error(StorageProviderException, 'boom!')
        project_storage_provider.reload
        expect(project_storage_provider).not_to be_is_initialized
      end
    end
  end
end
