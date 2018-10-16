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

    it { is_expected.to validate_uniqueness_of(:slug).allow_blank }
    it { is_expected.to allow_value('avalidslug').for(:slug) }
    it { is_expected.to allow_value('a_valid_slug').for(:slug) }
    it { is_expected.to allow_value('4_v4l1d_5lug').for(:slug) }
    it { is_expected.not_to allow_value('slug-with-dashes').for(:slug) }
    it { is_expected.not_to allow_value('SlugWithCaps').for(:slug) }
    it { is_expected.not_to allow_value('slug with spaces').for(:slug) }
    it { is_expected.not_to allow_value('slug.with.punctuation?').for(:slug) }
    it { is_expected.not_to allow_value("multiline\nslug").for(:slug) }

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

  describe '#initialize_storage' do
    subject { FactoryBot.build(:project) }
    let!(:auth_role) { FactoryBot.create(:auth_role, :project_admin) }
    let(:default_storage_provider) { FactoryBot.create(:storage_provider, :default) }
    it { is_expected.to callback(:initialize_storage).after(:create) }

    before do
      expect(default_storage_provider).to be_persisted
      expect(auth_role).to be_persisted
      expect(subject).not_to be_persisted
    end

    it 'should enqueue a ProjectStorageProviderInitializationJob with the default StorageProvider' do
      #TODO change this when storage_providers become configurable
      expect(StorageProvider.count).to eq 1
      expect(StorageProvider.default.id).to eq(default_storage_provider.id)
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

    context 'called' do
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

  it { is_expected.to respond_to(:slug_is_blank?) }
  describe '#slug_is_blank?' do
    subject { FactoryBot.build(:project) }

    context 'when slug is nil' do
      it { expect(subject.slug).to be_nil }
      it { expect(subject.slug_is_blank?).to be_truthy }
    end

    context 'when slug is empty string' do
      before { subject.slug = '' }
      it { expect(subject.slug).to eq '' }
      it { expect(subject.slug_is_blank?).to be_truthy }
    end

    context 'when slug is not blank' do
      before { subject.slug = 'n0tBl4nk' }
      it { expect(subject.slug).to eq 'n0tBl4nk' }
      it { expect(subject.slug_is_blank?).to be_falsey }
    end
  end

  describe '#generate_slug' do
    subject { FactoryBot.build(:project) }
    let(:call_generate_slug) { subject.generate_slug }
    it { is_expected.to respond_to(:generate_slug) }
    it { is_expected.to callback(:generate_slug).before(:validation).if(:slug_is_blank?) }

    it { expect(subject.slug).to be_nil }
    it 'populates slug and returns the new value' do
      expect(call_generate_slug).not_to be_nil
      expect(subject.slug).to eq call_generate_slug
    end
    it 'uses name to generate slug' do
      subject.name = 'foobarbaz'
      expect(call_generate_slug).to eq 'foobarbaz'
    end

    context 'called with name set to' do
      before {|example| subject.name = example.description }
      after { is_expected.to be_valid }
      it 'foo-bar baz' do
        expect(call_generate_slug).to eq 'foo_bar_baz'
      end
      it ' _ Foo-bär baz -_ ' do
        expect(call_generate_slug).to eq 'foo_bar_baz'
      end
      it '#@!' do
        expect(call_generate_slug).to eq '_'
      end

      context 'existing slug' do
        before do
          FactoryBot.create(:project, slug: 'foo_bar_baz')
        end
        it 'foo_bar_baz' do
          expect(call_generate_slug).to eq 'foo_bar_baz_1'
        end
      end

      context 'existing slugs' do
        before do
          FactoryBot.create(:project, slug: 'foo_bar_baz')
          (1..3).each do |i|
            FactoryBot.create(:project, slug: "foo_bar_baz_#{i}")
          end
        end
        it 'foo_bar_baz' do
          expect(call_generate_slug).to eq 'foo_bar_baz_4'
        end
      end
    end

    context 'called when project is invalid' do
      before do
        subject.name = 'foo bar baz'
        subject.description = nil
        is_expected.not_to be_valid
      end
      it { expect(call_generate_slug).to eq 'foo_bar_baz' }
    end
  end

  describe '#save with duplicate project name' do
    let(:previous) { FactoryBot.create(:project) }

    before do
      expect(previous).to be_persisted
    end

    context 'empty slug' do
      subject { FactoryBot.build(:project, name: previous.name) }
      it {
        expect(subject.save).to be_truthy
      }
    end

    context 'slug not taken' do
      subject { FactoryBot.build(:project, :with_slug, name: previous.name) }
      it {
        expect(Project.where(name: subject.name, slug: subject.slug)).not_to exist
        expect(subject.save).to be_truthy
      }
    end

    context 'slug taken' do
      subject { FactoryBot.build(:project, name: previous.name, slug: previous.slug) }
      it {
        expect(Project.where(name: subject.name, slug: subject.slug)).to exist
        expect(subject.save).not_to be_truthy
      }
    end
  end

  describe 'UnRestorable' do
    let(:valid_child_file) { FactoryBot.create(:data_file, :root, project: subject) }
    let(:invalid_child_file) { FactoryBot.create(:data_file, :root, :invalid, project: subject) }
    let(:child_folder) { FactoryBot.create(:folder, :root, project: subject) }
    let(:child_folder_file) { FactoryBot.create(:data_file, parent: child_folder)}
    let(:project_children) { [valid_child_file, child_folder] }

    it_behaves_like 'an UnRestorable ChildMinder', :project, :project_children

    describe '#manage_children' do
      context 'force_purgation' do
        context 'false' do
          it {
            expect(project_children).not_to be_empty
            expect(subject.force_purgation).to be_falsey
            subject.manage_deletion
            expect(ChildPurgationJob).not_to receive(:perform_later)
            subject.manage_children
          }
        end

        context 'true' do
          include_context 'with job runner', ChildPurgationJob
          let(:job_transaction) {
            subject.create_transaction('testing')
            ChildPurgationJob.initialize_job(subject)
          }
          before do
            @old_max = Rails.application.config.max_children_per_job
            Rails.application.config.max_children_per_job = 1
            expect(child_folder).to be_persisted
            child_folder.update_column(:is_deleted, true)
            expect(child_folder.is_deleted?).to be_truthy
            expect(valid_child_file).to be_persisted
            valid_child_file.update_column(:is_deleted, true)
            expect(valid_child_file.is_deleted?).to be_truthy
            expect(invalid_child_file).to be_persisted
            invalid_child_file.update_column(:is_deleted, true)
            expect(invalid_child_file.is_deleted?).to be_truthy
          end

          after do
            Rails.application.config.max_children_per_job = @old_max
          end

          it {
            expect(project_children).not_to be_empty
            subject.force_purgation = true
            expect(subject.force_purgation).to be_truthy
            subject.manage_deletion
            expect(ChildPurgationJob).to receive(:initialize_job)
              .with(subject)
              .exactly(subject.children.count).times
              .and_return(job_transaction)
            (1..subject.children.count).each do |page|
              expect(ChildPurgationJob).to receive(:perform_later).with(job_transaction, subject, page)
            end
            subject.manage_children
          }
        end
      end

      context 'when is_deleted not changed' do
        it {
          expect(project_children).not_to be_empty
          expect(subject.is_deleted_changed?).to be_falsey
          subject.manage_deletion
          expect(ChildPurgationJob).not_to receive(:perform_later)
          subject.manage_children
        }
      end

      context 'when deleted and is_deleted not changed' do
        subject { FactoryBot.create(:project, :deleted) }
        it {
          expect(project_children).not_to be_empty
          expect(subject.is_deleted_changed?).to be_falsey
          subject.manage_deletion
          expect(ChildPurgationJob).not_to receive(:perform_later)
          subject.manage_children
        }
      end

      context 'when is_deleted changed from false to true' do
        context 'has_children? true' do
          include_context 'with job runner', ChildPurgationJob
          let(:job_transaction) {
            subject.create_transaction('testing')
            ChildPurgationJob.initialize_job(subject)
          }
          before do
            @old_max = Rails.application.config.max_children_per_job
            Rails.application.config.max_children_per_job = 1
            expect(child_folder).to be_persisted
            child_folder.update_column(:is_deleted, true)
            expect(child_folder.is_deleted?).to be_truthy
            expect(valid_child_file).to be_persisted
            valid_child_file.update_column(:is_deleted, true)
            expect(valid_child_file.is_deleted?).to be_truthy
            expect(invalid_child_file).to be_persisted
            invalid_child_file.update_column(:is_deleted, true)
            expect(invalid_child_file.is_deleted?).to be_truthy
          end

          after do
            Rails.application.config.max_children_per_job = @old_max
          end

          it {
            expect(subject.has_children?).to be_truthy
            subject.is_deleted = true
            subject.manage_deletion
            expect(ChildPurgationJob).to receive(:initialize_job)
              .with(subject)
              .exactly(subject.children.count).times
              .and_return(job_transaction)
            (1..subject.children.count).each do |page|
              expect(ChildPurgationJob).to receive(:perform_later).with(job_transaction, subject, page)
            end
            subject.manage_children
          }
        end

        context 'has_children? false' do
          subject { FactoryBot.create(:project, is_deleted: true) }
          it {
            expect(subject.has_children?).to be_falsey
            subject.is_deleted = true
            subject.manage_deletion
            expect(ChildPurgationJob).not_to receive(:perform_later)
            subject.manage_children
          }
        end
      end

      context 'when is_deleted changed from true to false' do
        subject { FactoryBot.create(:project, is_deleted: true) }
        it {
          is_expected.to be_persisted
          expect(subject.is_deleted?).to be_truthy
          is_expected.not_to allow_value(false).for(:is_deleted)
        }
      end
    end #manage_children

    describe '#purge_children' do
      include_context 'with job runner', ChildPurgationJob
      let(:job_transaction) { ChildPurgationJob.initialize_job(subject) }
      let(:child_job_transaction) { ChildPurgationJob.initialize_job(child_folder) }
      let(:page) { 1 }

      before do
        expected_children.each do |cmc|
          expect(cmc).to be_persisted
        end
        expect(child_folder_file).to be_persisted
        @old_max = Rails.application.config.max_children_per_job
        Rails.application.config.max_children_per_job = subject.children.count + child_folder.children.count
      end

      after do
        Rails.application.config.max_children_per_job = @old_max
      end

      let(:expected_children) { [ child_folder, valid_child_file ] }
      let(:child_minder_children) { expected_children }
      it {
        subject.current_transaction = job_transaction
        expected_children.each do |cmc|
          expect(cmc.is_deleted?).to be_falsey
          expect(cmc.is_purged?).to be_falsey
        end
        child_minder_children.each do |cmc|
          expect(ChildPurgationJob).to receive(:initialize_job)
            .with(cmc)
            .and_return(child_job_transaction)
          expect(ChildPurgationJob).to receive(:perform_later)
            .with(child_job_transaction, cmc, page).and_call_original
        end
        subject.purge_children(page)

        expected_children.each do |cmc|
          expect(cmc.reload).to be_truthy
          expect(cmc.is_deleted?).to be_truthy
          expect(cmc.is_purged?).to be_truthy
        end
      }
    end #purge_children

    describe '#restore' do
      context 'is_deleted? true' do
        before do
          subject.update_columns(is_deleted: true)
        end
        it {
          expect {
            begin
              subject.restore(valid_child_file)
            rescue IncompatibleParentException => e
              expect(e.message).to eq("#{subject.kind} #{subject.id} is permenantly deleted, and cannot restore children.::Restore to a different project.")
              raise e
            end
          }.to raise_error(IncompatibleParentException)
        }
      end

      context 'when child is not a Container' do
        let(:incompatible_child) { FactoryBot.create(:file_version) }
        it {
          expect {
            begin
              subject.restore(incompatible_child)
            rescue IncompatibleParentException => e
              expect(e.message).to eq("Projects can only restore dds-file or dds-folder objects.::Perhaps you mistyped the object_kind.")
              raise e
            end
          }.to raise_error(IncompatibleParentException)
        }
      end

      context 'when child is a Container' do
        before do
          child.move_to_trashbin
          child.save
          child.reload
        end
        context 'from a child folder' do
          let(:child) { child_folder_file }
          it {
            expect {
              expect(child.is_deleted?).to be_truthy
              subject.restore(child)
              expect(child.is_deleted_changed?).to be_truthy
              expect(child.is_deleted?).to be_falsey
              expect(child.parent_id).to be_nil
            }.not_to raise_error
          }
        end

        context 'from root' do
          let(:child) { child_folder }
          it {
            expect {
              expect(child.is_deleted?).to be_truthy
              subject.restore(child)
              expect(child.is_deleted_changed?).to be_truthy
              expect(child.is_deleted?).to be_falsey
              expect(child.parent_id).to be_nil
            }.not_to raise_error
          }
        end
      end
    end
  end
end
