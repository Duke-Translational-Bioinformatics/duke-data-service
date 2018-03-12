require 'rails_helper'

RSpec.describe Project, type: :model do
  subject { FactoryBot.create(:project) }

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
      subject { FactoryBot.create(:project, :deleted) }
      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:description) }
      it { is_expected.not_to validate_presence_of(:creator_id) }
    end
  end

  describe '#set_project_admin' do
    subject { FactoryBot.build(:project) }
    let!(:auth_role) { FactoryBot.create(:auth_role, :project_admin) }
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
    let(:folder) { FactoryBot.create(:folder, :root, project: subject) }
    let(:file) { FactoryBot.create(:data_file, :root, project: subject) }
    let(:invalid_file) { FactoryBot.create(:data_file, :root, :invalid, project: subject) }

    it_behaves_like 'a ChildMinder', :project, :file, :invalid_file, :folder
  end

  describe '#initialize_storage' do
    subject { FactoryBot.build(:project) }
    let!(:auth_role) { FactoryBot.create(:auth_role, :project_admin) }
    let(:default_storage_provider) { FactoryBot.create(:storage_provider) }
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

  describe '#manage_container_index_project' do
    it { is_expected.to respond_to(:manage_container_index_project) }
    it { is_expected.to callback(:manage_container_index_project).after(:update) }

    context 'when name is changed' do
      let(:new_name) { "#{Faker::Team.name}_#{rand(10**3)}" }

      context 'when project has containers' do
        let(:root_folder) { FactoryBot.create(:folder, :root, project: subject) }
        let(:folder_child) { FactoryBot.create(:data_file, parent: root_folder, project: subject) }
        let(:root_file) { FactoryBot.create(:data_file, :root, project: subject) }

        let(:job_transaction) {
          subject.create_transaction('testing')
          ProjectContainerElasticsearchUpdateJob.initialize_job(subject)
        }
        include_context 'with job runner', ProjectContainerElasticsearchUpdateJob
        before do
          @old_max = Rails.application.config.max_children_per_job
          Rails.application.config.max_children_per_job = 1
          expect(root_folder).to be_persisted
          expect(root_folder.is_deleted?).to be_falsey
          expect(folder_child).to be_persisted
          expect(folder_child.is_deleted?).to be_falsey
        end

        after do
          Rails.application.config.max_children_per_job = @old_max
        end
        it {
          subject.name = new_name
          num_containers = subject.containers.count
          expect(num_containers).to be > 0
          expect(subject.name_changed?).to be_truthy
          expect(ProjectContainerElasticsearchUpdateJob).to receive(:initialize_job)
            .exactly(num_containers).times
            .with(subject).and_return(job_transaction)
          (1..num_containers).each do |page|
            expect(ProjectContainerElasticsearchUpdateJob).to receive(:perform_later)
              .with(job_transaction, subject, page)
          end
          subject.manage_container_index_project
        }
      end

      context 'when project does not have containers' do
        it {
          subject.name = new_name
          expect(subject.containers.count).to eq 0
          expect(subject.name_changed?).to be_truthy
          expect(ProjectContainerElasticsearchUpdateJob).not_to receive(:perform_later)
          subject.manage_container_index_project
        }
      end
    end

    context 'when name is not changed' do
      let(:new_description) { Faker::Hacker.say_something_smart }

      it {
        subject.description = new_description
        expect(subject.name_changed?).to be_falsey
        expect(ProjectContainerElasticsearchUpdateJob).not_to receive(:perform_later)
        subject.manage_container_index_project
      }
    end
  end

  describe '#update_container_elasticsearch_index_project' do
    let(:root_folder) { FactoryBot.create(:folder, :root, project: subject) }
    let(:folder_child) { FactoryBot.create(:data_file, parent: root_folder, project: subject) }
    let(:root_file) { FactoryBot.create(:data_file, :root, project: subject) }

    it { is_expected.not_to respond_to(:update_container_elasticsearch_index_project).with(0).arguments }
    it { is_expected.to respond_to(:update_container_elasticsearch_index_project).with(1).argument }

    context 'called', :vcr do
      let(:page) { 1 }
      let(:new_name) { "#{Faker::Team.name}_#{rand(10**3)}" }
      include_context 'elasticsearch prep', [:root_folder, :folder_child, :root_file], [:root_folder, :folder_child, :root_file]

      before do
        expect(root_folder).to be_persisted
        expect(folder_child).to be_persisted
        expect(root_file).to be_persisted
      end

      it {
        project_container_count = subject.containers.page(page).count
        expect(project_container_count).to be > 0

        container_search = FolderFilesResponse.new
        container_search.filter [{'project.id' => [subject.id]}]
        response = container_search.search
        results = response.results
        expect(results.count).to eq(project_container_count)
        subject.containers.page(page).each do |c|
          c_index = c.as_indexed_json
          expect(c_index[:project][:name]).to eq(subject.name)
          expect(results).to include c_index.as_json
        end

        subject.update_column(:name, new_name)
        subject.reload
        subject.update_container_elasticsearch_index_project(page)

        container_search = FolderFilesResponse.new
        container_search.filter [{'project.id' => [subject.id]}]
        response = container_search.search
        results = response.results
        expect(results.count).to eq(project_container_count)
        subject.containers.page(page).each do |c|
          c_index = c.as_indexed_json
          expect(c_index[:project][:name]).to eq(new_name)
          expect(results).to include c_index.as_json
        end
      }
    end
  end
end
