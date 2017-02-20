require 'rails_helper'

RSpec.describe ProjectStorageProviderInitializationJob, type: :job do
  let(:project) { FactoryGirl.create(:project) }
  let!(:storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }


  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}project_storage_provider_initialization") }

  context 'perform_now', :vcr do
    it 'should require a project argument' do
      expect {
        described_class.perform_now
      }.to raise_error(ArgumentError)
      expect {
        described_class.perform_now(storage_provider: storage_provider)
      }.to raise_error(ArgumentError)
    end

    it 'should require a storage_provider argument' do
      expect {
        described_class.perform_now
      }.to raise_error(ArgumentError)
      expect {
        described_class.perform_now(project: project)
      }.to raise_error(ArgumentError)
    end

    it 'should create the container for the project' do
      expect(storage_provider.get_container_meta(project.id)).to be_nil
      described_class.perform_now(
        storage_provider: storage_provider,
        project: project
      )
      expect(storage_provider.get_container_meta(project.id)).to be
    end
  end
end
