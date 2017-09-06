require 'rails_helper'

RSpec.describe Project, type: :model do
  subject { FactoryGirl.create(:project) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let(:expected_kind) { 'dds-project' }
    let(:kinded_class) { Project }
    let(:serialized_kind) { true }
  end
  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a job_transactionable model'

  describe 'associations' do
    it 'should have many project permissions' do
      should have_many(:project_permissions)
    end

    it 'should have many data_files' do
      should have_many(:data_files)
    end

    it 'should have a creator' do
      should belong_to(:creator)
    end

    it 'should have many uploads' do
      should have_many(:uploads)
    end

    it 'should have many affiliations' do
      should have_many(:affiliations)
    end

    it 'should have many children' do
      should have_many(:children).class_name('Container').conditions(parent_id: nil)
    end

    it 'should have many containers' do
      should have_many(:containers)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.not_to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.not_to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:creator_id) }

    context 'when is_deleted true' do
      subject { FactoryGirl.create(:project, :deleted) }
      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:description) }
      it { is_expected.not_to validate_presence_of(:creator_id) }
    end
  end

  describe '#set_project_admin' do
    subject { FactoryGirl.build(:project) }
    let!(:auth_role) { FactoryGirl.create(:auth_role, :project_admin) }
    it { is_expected.to callback(:set_project_admin).after(:create) }

    it 'should give the project creator a project_admin permission' do
      expect(auth_role).to be_persisted
      expect(AuthRole.where(id: 'project_admin').count).to eq(1)
      expect {
        expect(subject.save).to be_truthy
      }.to change{ProjectPermission.count}.by(1)
      expect(subject.project_permissions.count).to eq(1)
      permission = subject.project_permissions.first
      expect(permission).to be_persisted
      expect(permission.auth_role).to eq(auth_role)
      expect(permission.user).to eq(subject.creator)
    end

    it 'should fail gracefullly if project_admin AuthRole does not exist' do
      auth_role.destroy
      expect(AuthRole.where(id: 'project_admin').count).to eq(0)
      expect {
        expect(subject.save).to be_truthy
      }.to change{ProjectPermission.count}.by(0)
      expect(subject.project_permissions.count).to eq(0)
    end
  end

  context 'with descendants' do
    let(:folder) { FactoryGirl.create(:folder, :root, project: subject) }
    let(:file) { FactoryGirl.create(:data_file, :root, project: subject) }
    let(:invalid_file) { FactoryGirl.create(:data_file, :root, :invalid, project: subject) }
    it_behaves_like 'an UnRestorable ChildMinder', :project, :file, :invalid_file, :folder
  end

  describe '#initialize_storage' do
    subject { FactoryGirl.build(:project) }
    let!(:auth_role) { FactoryGirl.create(:auth_role, :project_admin) }
    let(:default_storage_provider) { FactoryGirl.create(:storage_provider) }
    it { is_expected.to callback(:initialize_storage).after(:create) }

    before do
      expect(default_storage_provider).to be_persisted
      expect(auth_role).to be_persisted
      expect(subject).not_to be_persisted
    end

    it 'should enqueue a ProjectStorageProviderInitializationJob with the default StorageProvider' do
      #TODO change this when storage_providers become configurable
      expect(StorageProvider.count).to eq 1
      expect(StorageProvider.first.id).to eq(default_storage_provider.id)
      expect(subject).to receive(:initialize_storage).and_call_original
      expect {
        subject.save
      }.to have_enqueued_job(ProjectStorageProviderInitializationJob)
    end

    it 'rollsback when ProjectStorageProviderInitializationJob::perform_later raises an error' do
      allow(ProjectStorageProviderInitializationJob).to receive(:perform_later).and_raise("boom!")
      expect{
        expect{subject.save}.to raise_error("boom!")
      }.not_to change{described_class.count}
    end
  end
end
