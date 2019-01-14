require 'rails_helper'

RSpec.describe ProjectStorageProvider, type: :model do
  # Associations
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:storage_provider) }

  # Validations
  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:storage_provider) }
  it 'validates uniqueness of storage_provider and project' do
    # intercepting initialize_storage callback to prevent error
    allow_any_instance_of(described_class).to receive(:initialize_storage)
    is_expected.to validate_uniqueness_of(:storage_provider_id).scoped_to(:project_id)
  end

  it { is_expected.to respond_to(:initialize_storage).with(0).arguments }
  it { is_expected.to callback(:initialize_storage).after(:create) }
  describe '#initialize_storage' do
    subject { FactoryBot.build(:project_storage_provider, project: project, storage_provider: storage_provider) }
    let(:project) { FactoryBot.create(:project) }
    let!(:auth_role) { FactoryBot.create(:auth_role, :project_admin) }
    let(:storage_provider) { FactoryBot.create(:storage_provider) }

    before(:example) do
      allow_any_instance_of(Project).to receive(:initialize_storage)
      expect(subject).not_to be_persisted
    end

    it 'should enqueue a ProjectStorageProviderInitializationJob with project and storage_provider' do
      expect(subject).to receive(:initialize_storage).and_call_original
      expect {
        subject.save
      }.to have_enqueued_job(ProjectStorageProviderInitializationJob)
        .with(job_transaction: instance_of(JobTransaction), project_storage_provider: subject)
    end

    it 'rollsback when ProjectStorageProviderInitializationJob::perform_later raises an error' do
      allow(ProjectStorageProviderInitializationJob).to receive(:perform_later).and_raise("boom!")
      expect{
        expect{subject.save}.to raise_error("boom!")
      }.not_to change{described_class.count}
    end
  end
end
