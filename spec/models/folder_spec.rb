require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:grand_child_folder) { FactoryGirl.create(:folder, parent: child_folder) }
  let(:grand_child_file) { FactoryGirl.create(:data_file, parent: child_folder) }
  let(:invalid_file) { FactoryGirl.create(:data_file, :invalid, parent: child_folder) }
  let(:project) { subject.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let(:expected_kind) { 'dds-folder' }
    let(:kinded_class) { Folder }
    let(:serialized_kind) { true }
  end
  it_behaves_like 'a logically deleted model'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:parent) }
    it { is_expected.to have_many(:project_permissions).through(:project) }
    it { is_expected.to have_many(:children).class_name('Container').with_foreign_key('parent_id').autosave(true) }
    it { is_expected.to have_many(:folders).with_foreign_key('parent_id') }
    it { is_expected.to have_many(:meta_templates) }
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
      expect(subject).to be_valid
      should allow_value(project.id).for(:project_id)
      should_not allow_value(other_project.id).for(:project_id)
      should allow_value(project.id).for(:project_id)
      expect(subject).to be_valid
      should allow_value(other_project).for(:project)
      expect(subject).not_to be_valid
    end

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    it 'should not be its own parent' do
      should_not allow_value(subject).for(:parent)
      expect(child_folder.reload).to be_truthy
      should_not allow_value(subject.id).for(:parent_id)
    end

    context 'with children' do
      subject { child_folder.parent }

      it 'should allow is_deleted to be set to true' do
        should allow_value(true).for(:is_deleted)
        expect(subject.is_deleted?).to be_truthy
        should allow_value(false).for(:is_deleted)
      end

      it 'should not allow child as parent' do
        should_not allow_value(child_folder).for(:parent)
        expect(child_folder.reload).to be_truthy
        should_not allow_value(child_folder.id).for(:parent_id)
      end
    end

    context 'with invalid child file' do
      subject { invalid_file.parent }

      it 'should allow is_deleted to be set to true' do
        should allow_value(true).for(:is_deleted)
        expect(subject.is_deleted?).to be_truthy
        should allow_value(false).for(:is_deleted)
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

  describe '#manage_children' do
    it {
      is_expected.to respond_to(:manage_children)
    }

    context 'when is_deleted not changed' do
      it {
        expect(subject.is_deleted_changed?).to be_falsey
        yield_called = false
        expect(subject).not_to receive(:delete_children)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end

    context 'when is_deleted changed from false to true' do
      it {
        subject.is_deleted = true
        yield_called = false
        expect(subject).to receive(:delete_children)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end

    context 'when is_deleted changed from true to false' do
      subject { FactoryGirl.create(:folder, is_deleted: true) }
      it {
        expect(subject.is_deleted?).to be_truthy
        subject.is_deleted = false
        yield_called = false
        expect(subject).not_to receive(:delete_children)
        subject.manage_children do
          yield_called = true
        end
        expect(yield_called).to be_truthy
      }
    end

    context 'when something else changed' do
      it {
        subject.name = 'changed_name'
        expect(subject.is_deleted?).to be_falsey
        is_expected.to be_changed
        expect(subject.is_deleted_changed?).to be_falsey
        expect(subject.newly_deleted).to be_falsey
      }
    end
  end
  describe '#delete_children' do
    it {
      is_expected.to respond_to(:delete_children)
    }
    it {
      expect(grand_child_file).to be_persisted
      expect(grand_child_file.is_deleted?).to be_falsey
      expect(invalid_file).to be_persisted
      expect(invalid_file.is_deleted?).to be_falsey
      subject.delete_children
      grand_child_file.reload
      expect(grand_child_file.is_deleted?).to be_truthy
      invalid_file.reload
      expect(invalid_file.is_deleted?).to be_truthy
    }

    it {
      expect(grand_child_folder).to be_persisted
      expect(subject.folder_ids).to include grand_child_folder.id
      expect(FolderDeletionJob).to receive(:perform_later).with(grand_child_folder.id)
      subject.delete_children
    }
  end

  describe 'callbacks' do
    it { is_expected.to callback(:manage_children).around(:update) }
  end

  describe '.creator' do
    let(:creator) { FactoryGirl.create(:user) }
    it { is_expected.to respond_to :creator }

    context 'with nil creation audit' do
      subject {
        FactoryGirl.create(:folder)
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
          FactoryGirl.create(:folder)
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
      kind: {type: "string", index: "not_analyzed"},
      id: {type: "string", index: "not_analyzed"},
      name: {type: "string"},
      label: {type: "string"},
      parent: {type: "object"},
      audit: {type: "object"},
      project: {type: "object"},
      ancestors: {type: "object"},
      is_deleted: {type: "boolean"},
      created_at: {type: "date"},
      updated_at: {type: "date"},
      creator: {type: "object"}
    }}

    it_behaves_like 'an Elasticsearch::Model'
    it_behaves_like 'an Elasticsearch index mapping model' do
      it {
        #parent
        expect(subject[:folder][:properties][:parent]).to have_key :properties
        expect(subject[:folder][:properties][:parent][:properties]).to have_key :id
        expect(subject[:folder][:properties][:parent][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:parent][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:parent][:properties]).to have_key :name
        expect(subject[:folder][:properties][:parent][:properties][:name][:type]).to eq "string"

        #creator
        expect(subject[:folder][:properties][:creator]).to have_key :properties
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :id
        expect(subject[:folder][:properties][:creator][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :username
        expect(subject[:folder][:properties][:creator][:properties][:username][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :email
        expect(subject[:folder][:properties][:creator][:properties][:email][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :first_name
        expect(subject[:folder][:properties][:creator][:properties][:first_name][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :last_name
        expect(subject[:folder][:properties][:creator][:properties][:last_name][:type]).to eq "string"

        #project
        expect(subject[:folder][:properties][:project]).to have_key :properties
        expect(subject[:folder][:properties][:project][:properties]).to have_key :id
        expect(subject[:folder][:properties][:project][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:project][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:project][:properties]).to have_key :name
        expect(subject[:folder][:properties][:project][:properties][:name][:type]).to eq "string"

        #audit
        expect(subject[:folder][:properties][:audit]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties]).to have_key :created_on
        expect(subject[:folder][:properties][:audit][:properties][:created_on][:type]).to eq "date"
        expect(subject[:folder][:properties][:audit][:properties]).to have_key :created_by
        expect(subject[:folder][:properties][:audit][:properties][:created_by]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties]).to have_key :username
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:username][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties]).to have_key :full_name
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:full_name][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties]).to have_key :agent
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent][:properties]).to have_key :name
        expect(subject[:folder][:properties][:audit][:properties][:created_by][:properties][:agent][:properties][:name][:type]).to eq "string"

        expect(subject[:folder][:properties][:audit][:properties]).to have_key :last_updated_on
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_on][:type]).to eq "date"
        expect(subject[:folder][:properties][:audit][:properties]).to have_key :last_updated_by
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties]).to have_key :username
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:username][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties]).to have_key :full_name
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:full_name][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties]).to have_key :agent
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent][:properties]).to have_key :name
        expect(subject[:folder][:properties][:audit][:properties][:last_updated_by][:properties][:agent][:properties][:name][:type]).to eq "string"

        expect(subject[:folder][:properties][:audit][:properties]).to have_key :deleted_on
        expect(subject[:folder][:properties][:audit][:properties][:deleted_on][:type]).to eq "date"
        expect(subject[:folder][:properties][:audit][:properties]).to have_key :deleted_by
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties]).to have_key :username
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:username][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties]).to have_key :full_name
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:full_name][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties]).to have_key :agent
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent]).to have_key :properties
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent][:properties]).to have_key :id
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent][:properties]).to have_key :name
        expect(subject[:folder][:properties][:audit][:properties][:deleted_by][:properties][:agent][:properties][:name][:type]).to eq "string"

        #ancestors
        expect(subject[:folder][:properties][:ancestors]).to have_key :properties
        expect(subject[:folder][:properties][:ancestors][:properties]).to have_key :kind
        expect(subject[:folder][:properties][:ancestors][:properties][:kind][:type]).to eq "string"
        expect(subject[:folder][:properties][:ancestors][:properties][:kind][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:ancestors][:properties]).to have_key :id
        expect(subject[:folder][:properties][:ancestors][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:ancestors][:properties][:id][:index]).to eq "not_analyzed"
        expect(subject[:folder][:properties][:ancestors][:properties]).to have_key :name
        expect(subject[:folder][:properties][:ancestors][:properties][:name][:type]).to eq "string"
      }
    end
  end
end
