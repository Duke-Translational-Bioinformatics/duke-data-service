require 'rails_helper'

RSpec.describe ProjectStorageProviderInitializationJob, type: :job do
  let(:project) { FactoryGirl.create(:project) }
  let!(:storage_provider) { FactoryGirl.create(:storage_provider, :swift) }
  it { is_expected.to be_an ApplicationJob }

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

  #uncomment this when we actually configure the application with
  #a queue_adaptor, such as sidekiq or delayed_job
  # context 'perform_later' do
  #   it 'should enqueue with the correct arguments' do
  #     it 'should create the container for the project' do
  #       ActiveJob::Base.queue_adapter = :test
  #       expect(storage_provider.get_container_meta(project.id)).to be_nil
  #       expect {
  #         described_class.perform_later(
  #           storage_provider: storage_provider,
  #           project: project
  #         )
  #       }.to have_enqueued_job(described_class).with(
  #         storage_provider: storage_provider,
  #         project: project
  #       )
  #     end
  #   end
  # end
end
