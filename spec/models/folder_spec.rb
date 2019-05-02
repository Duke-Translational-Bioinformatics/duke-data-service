require 'rails_helper'

RSpec.describe Folder, type: :model do
  include_context 'mock all Uploads StorageProvider'
  subject { FactoryBot.create(:folder, :with_parent) }
  let(:immediate_child_folder) { FactoryBot.create(:folder, parent: subject) }
  let(:immediate_child_file) { FactoryBot.create(:data_file, parent: subject) }
  let(:folder_children) {[ immediate_child_file, immediate_child_folder ]}
  let(:folder_child_minder_children) { folder_children }
  let(:project) { subject.project }
  let(:other_project) { FactoryBot.create(:project) }
  let(:other_folder) { FactoryBot.create(:folder, project: other_project) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let(:expected_kind) { 'dds-folder' }
    let(:kinded_class) { Folder }
    let(:serialized_kind) { true }
  end
  it_behaves_like 'a logically deleted model'
  it_behaves_like 'a job_transactionable model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to belong_to(:deleted_from_parent) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to have_many(:children).class_name('Container').with_foreign_key('parent_id').autosave(true) }
    it { is_expected.to have_many(:folders).with_foreign_key('parent_id') }
  end

  describe 'validations' do
    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should not allow project_id to be changed' do
      should allow_value(project).for(:project)
      is_expected.to be_valid
      should allow_value(project.id).for(:project_id)
      should_not allow_value(other_project.id).for(:project_id)
      should allow_value(project.id).for(:project_id)
      is_expected.to be_valid
      should allow_value(other_project).for(:project)
      is_expected.not_to be_valid
    end

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    it 'should not be its own parent' do
      should_not allow_value(subject).for(:parent)
      expect(subject.reload).to be_truthy
      should_not allow_value(subject.id).for(:parent_id)
    end

    context 'with children' do
      it 'should allow is_deleted to be set to true' do
        is_expected.to allow_value(true).for(:is_deleted)
        expect(subject.is_deleted?).to be_truthy
        is_expected.to allow_value(false).for(:is_deleted)
      end

      it 'should not allow child as parent' do
        is_expected.not_to allow_value(subject).for(:parent)
        expect(subject.reload).to be_truthy
        is_expected.not_to allow_value(subject.id).for(:parent_id)
      end
    end

    context 'with invalid child file' do
      it 'should allow is_deleted to be set to true' do
        is_expected.to allow_value(true).for(:is_deleted)
        expect(subject.is_deleted?).to be_truthy
        is_expected.to allow_value(false).for(:is_deleted)
      end
    end
  end

  describe '#parent=' do
    it 'should set project to parent.project' do
      expect(subject.parent).not_to eq other_folder
      expect(subject.project).not_to eq other_folder.project
      expect(subject.project_id).not_to eq other_folder.project_id
      should allow_value(other_folder).for(:parent)
      expect(subject.parent).to eq other_folder
      expect(subject.project).to eq other_folder.project
      expect(subject.project_id).to eq other_folder.project_id
    end
  end

  describe '#parent_id=' do
    it 'should set project to parent.project' do
      expect(subject.parent).not_to eq other_folder
      expect(subject.project).not_to eq other_folder.project
      expect(subject.project_id).not_to eq other_folder.project_id
      should allow_value(other_folder.id).for(:parent_id)
      expect(subject.parent).to eq other_folder
      expect(subject.project).to eq other_folder.project
      expect(subject.project_id).to eq other_folder.project_id
    end
  end

  describe '.creator' do
    let(:creator) { FactoryBot.create(:user) }
    it { is_expected.to respond_to :creator }

    context 'with nil creation audit' do
      subject {
        FactoryBot.create(:folder)
      }

      around(:each) do |example|
          Folder.auditing_enabled = false
          example.run
          Folder.auditing_enabled = true
      end

      it {
        expect(subject.audits.find_by(action: 'create')).to be_nil
        expect(subject.creator).to be_nil
      }
    end

    context 'with creation audit' do
      subject {
        Audited.audit_class.as_user(creator) do
          FactoryBot.create(:folder)
        end
      }

      it {
        expect(subject.audits.find_by(action: 'create')).not_to be_nil
        expect(subject.creator.id).to eq(subject.audits.find_by(action: 'create').user.id)
      }
    end
  end

  describe 'elasticsearch' do
    let(:search_serializer) { Search::FolderSerializer }
    let(:property_mappings) {{
      kind: {type: "string"},
      name: {type: "string"}, #name
      is_deleted: {type: "boolean"},
      project: {type: "object"}
    }}
    include_context 'with job runner', ElasticsearchIndexJob

    it_behaves_like 'a SearchableModel'
    it_behaves_like 'an Elasticsearch index mapping model' do
      it {
        #kind.raw
        expect(subject[:folder][:properties][:kind]).to have_key :fields
        expect(subject[:folder][:properties][:kind][:fields]).to have_key :raw
        expect(subject[:folder][:properties][:kind][:fields][:raw][:type]).to eq "string"
        expect(subject[:folder][:properties][:kind][:fields][:raw][:index]).to eq "not_analyzed"

        #project.id.raw
        expect(subject[:folder][:properties][:project]).to have_key :properties
        expect(subject[:folder][:properties][:project][:properties]).to have_key :id
        expect(subject[:folder][:properties][:project][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:project][:properties][:id]).to have_key :fields
        expect(subject[:folder][:properties][:project][:properties][:id][:fields]).to have_key :raw
        expect(subject[:folder][:properties][:project][:properties][:id][:fields][:raw][:type]).to eq "string"
        expect(subject[:folder][:properties][:project][:properties][:id][:fields][:raw][:index]).to eq "not_analyzed"

        #project.name.raw
        expect(subject[:folder][:properties][:project][:properties]).to have_key :name
        expect(subject[:folder][:properties][:project][:properties][:name][:type]).to eq "string"
        expect(subject[:folder][:properties][:project][:properties][:name]).to have_key :fields
        expect(subject[:folder][:properties][:project][:properties][:name][:fields]).to have_key :raw
        expect(subject[:folder][:properties][:project][:properties][:name][:fields][:raw][:type]).to eq "string"
        expect(subject[:folder][:properties][:project][:properties][:name][:fields][:raw][:index]).to eq "not_analyzed"
      }
    end
  end

  it_behaves_like 'a Restorable ChildMinder', :folder, :folder_children, :folder_child_minder_children do
    let(:child_folder_file) { FactoryBot.create(:data_file, parent: immediate_child_folder)}
    before do
      expect(child_folder_file).to be_persisted
      child_folder_file.update_column(:is_deleted, true)
    end
  end
  it_behaves_like 'a Purgable ChildMinder', :folder, :folder_children, :folder_child_minder_children do
    let(:child_folder_file) { FactoryBot.create(:data_file, parent: immediate_child_folder)}
    before do
      expect(child_folder_file).to be_persisted
      child_folder_file.update_column(:is_deleted, true)
    end
  end


  describe '#restore' do
    context 'is_deleted? true' do
      include_context 'trashed resource'

      it {
        expect {
          begin
            subject.restore(immediate_child_file)
          rescue TrashbinParentException => e
            expect(e.message).to eq("#{subject.kind} #{subject.id} is deleted, and cannot restore children.::Restore #{subject.kind} #{subject.id}.")
            raise e
          end
        }.to raise_error(TrashbinParentException)
      }
    end

    context 'when child is not a Container' do
      let(:incompatible_child) { FactoryBot.create(:file_version) }
      it {
        expect {
          begin
            subject.restore(incompatible_child)
          rescue IncompatibleParentException => e
            expect(e.message).to eq("Folders can only restore dds-file or dds-folder objects.::Perhaps you mistyped the object_kind.")
            raise e
          end
        }.to raise_error(IncompatibleParentException)
      }
    end

    context 'when child is a Container' do
      include_context 'trashed resource', :child

      context 'from another folder' do
        let(:child) { FactoryBot.create(:folder, project: project, parent: immediate_child_folder) }
        it {
          expect {
            expect(child.is_deleted?).to be_truthy
            subject.restore(child)
            expect(child.is_deleted_changed?).to be_truthy
            expect(child.is_deleted?).to be_falsey
            expect(child.parent_id).to eq(subject.id)
          }.not_to raise_error
        }
      end

      context 'from this folder' do
        let(:child) { immediate_child_file }
        it {
          expect {
            expect(child.is_deleted?).to be_truthy
            subject.restore(child)
            expect(child.is_deleted_changed?).to be_truthy
            expect(child.is_deleted?).to be_falsey
            expect(child.parent_id).to eq(subject.id)
          }.not_to raise_error
        }
      end
    end
  end

  describe '#purge' do
    context 'undeleted' do
      it {
        expect(subject.is_deleted?).to be_falsey
        expect(subject.is_purged?).to be_falsey
        subject.purge
        expect(subject.is_deleted_changed?).to be_truthy
        expect(subject.is_purged_changed?).to be_truthy
        expect(subject.is_deleted?).to be_truthy
        expect(subject.is_purged?).to be_truthy
      }
    end

    context 'deleted' do
      include_context 'trashed resource'

      it {
        expect(subject.is_deleted?).to be_truthy
        expect(subject.is_purged?).to be_falsey
        subject.purge
        expect(subject.is_deleted_changed?).to be_falsey
        expect(subject.is_purged_changed?).to be_truthy
        expect(subject.is_purged?).to be_truthy
      }
    end
  end

  describe '#move_to_trashbin' do
    let(:original_parent) { subject.parent }
    it { is_expected.to respond_to(:move_to_trashbin) }

    it {
      expect(subject.is_deleted?).to be_falsey
      expect(original_parent).not_to be_nil
      expect(subject.deleted_from_parent_id).to be_nil
      expect(subject.deleted_from_parent).to be_nil

      subject.move_to_trashbin

      expect(subject.is_deleted?).to be_truthy
      expect(subject.parent_id).to be_nil
      expect(subject.parent).to be_nil
      expect(subject.deleted_from_parent_id).not_to be_nil
      expect(subject.deleted_from_parent).not_to be_nil
      expect(subject.deleted_from_parent).to eq(original_parent)
    }
  end

  describe '#restore_from_trashbin' do
    let(:original_parent) { subject.deleted_from_parent }
    include_context 'trashed resource'

    before do
      expect(subject.is_deleted?).to be_truthy
      expect(subject.parent_id).to be_nil
      expect(subject.parent).to be_nil
      expect(original_parent).not_to be_nil
    end

    context 'to original parent' do
      context 'folder' do
        it {
          subject.restore_from_trashbin

          expect(subject.is_deleted?).to be_falsey
          expect(subject.parent_id).not_to be_nil
          expect(subject.parent).not_to be_nil
          expect(subject.deleted_from_parent_id).to be_nil
          expect(subject.deleted_from_parent).to be_nil
          expect(subject.parent).to eq(original_parent)
        }
      end

      context 'project' do
        subject { other_folder }
        let(:original_parent) { subject.project }

        it {
          subject.restore_from_trashbin

          expect(subject.is_deleted?).to be_falsey
          expect(subject.parent_id).to be_nil
          expect(subject.parent).to be_nil
          expect(subject.deleted_from_parent_id).to be_nil
          expect(subject.deleted_from_parent).to be_nil
          expect(subject.project).to eq(original_parent)
        }
      end
    end

    context 'to new parent folder' do
      context 'in original project' do
        let(:new_parent) { FactoryBot.create(:folder, project: project) }

        it {
          subject.restore_from_trashbin new_parent

          expect(subject.is_deleted?).to be_falsey
          expect(subject.parent_id).not_to be_nil
          expect(subject.parent).not_to be_nil
          expect(subject.deleted_from_parent_id).to be_nil
          expect(subject.deleted_from_parent).to be_nil
          expect(subject.parent).not_to eq(original_parent)
          expect(subject.parent).to eq(new_parent)
          expect(subject.project_id).to eq(new_parent.project_id)
          expect(subject).to be_valid
        }
      end

      context 'in different project' do
        let(:new_parent) { FactoryBot.create(:folder, project: other_project) }

        it {
          subject.restore_from_trashbin new_parent

          expect(subject.is_deleted?).to be_falsey
          expect(subject.parent_id).not_to be_nil
          expect(subject.parent).not_to be_nil
          expect(subject.deleted_from_parent_id).to be_nil
          expect(subject.deleted_from_parent).to be_nil
          expect(subject.parent).not_to eq(original_parent)
          expect(subject.parent).to eq(new_parent)
          expect(subject.project_id).to eq(new_parent.project_id)
          expect(subject).not_to be_valid
        }
      end
    end

    context 'to original project root' do
      let(:target_project) { project }

      it {
        subject.restore_from_trashbin target_project

        expect(subject.is_deleted?).to be_falsey
        expect(subject.parent_id).to be_nil
        expect(subject.parent).to be_nil
        expect(subject.deleted_from_parent_id).to be_nil
        expect(subject.deleted_from_parent).to be_nil
        expect(subject.project_id).to eq(target_project.id)
        expect(subject).to be_valid
      }
    end

    context 'to different project root' do
      let(:target_project) { other_project }

      it {
        subject.restore_from_trashbin target_project

        expect(subject.is_deleted?).to be_falsey
        expect(subject.parent_id).to be_nil
        expect(subject.parent).to be_nil
        expect(subject.deleted_from_parent_id).to be_nil
        expect(subject.deleted_from_parent).to be_nil
        expect(subject.project_id).to eq(target_project.id)
        expect(subject).not_to be_valid
      }
    end

    context 'to non project or folder' do
      let(:new_parent) { immediate_child_file }

      it {
        expect {
          subject.restore_from_trashbin new_parent
        }.to raise_error(IncompatibleParentException)
      }
    end
  end
end
