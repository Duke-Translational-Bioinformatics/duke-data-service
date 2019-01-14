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
    include_context 'tracking job', :job_transaction
    it 'should create the container for the project' do
      allow_any_instance_of(Project).to receive(:initialize_storage)
      allow_any_instance_of(ProjectStorageProvider).to receive(:initialize_storage)
      expect(mocked_storage_provider).to receive(:initialize_project)
        .with(project)
      described_class.perform_now(
        job_transaction: job_transaction,
        project_storage_provider: project_storage_provider
      )
      project.reload
      expect(project).to be_is_consistent
    end
  end
end
