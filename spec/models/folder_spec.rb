require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:root_folder) { FactoryGirl.create(:folder, :root) }
  let(:grand_child_folder) { FactoryGirl.create(:folder, parent: child_folder) }
  let(:grand_child_file) { FactoryGirl.create(:data_file, parent: child_folder) }
  let(:invalid_file) { FactoryGirl.create(:data_file, :invalid, parent: child_folder) }
  let(:project) { subject.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind'
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

  describe '.parent=' do
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

  describe '.parent_id=' do
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

  describe '.is_deleted= on parent' do
    subject { child_folder.parent }

    it 'should set is_deleted on children' do
      expect(child_folder.is_deleted?).to be_falsey
      should allow_value(true).for(:is_deleted)
      expect(subject.save).to be_truthy
      expect(child_folder.reload).to be_truthy
      expect(child_folder.is_deleted?).to be_truthy
    end

    it 'should set is_deleted on grand-children' do
      expect(grand_child_folder.is_deleted?).to be_falsey
      expect(grand_child_file.is_deleted?).to be_falsey
      should allow_value(true).for(:is_deleted)
      expect(subject.save).to be_truthy
      expect(grand_child_folder.reload).to be_truthy
      expect(grand_child_file.reload).to be_truthy
      expect(grand_child_folder.is_deleted?).to be_truthy
      expect(grand_child_file.is_deleted?).to be_truthy
    end

    context 'with invalid child file' do
      subject { invalid_file.parent }

      it 'should set is_deleted on children' do
        expect(invalid_file.is_deleted?).to be_falsey
        should allow_value(true).for(:is_deleted)
        expect(subject.save).to be_truthy
        expect(invalid_file.reload).to be_truthy
        expect(invalid_file.is_deleted?).to be_truthy
      end
    end
  end

  describe '#creator' do
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
      id: "string",
      name: "string",
      is_deleted: "boolean",
      created_at: "date",
      updated_at: "date",
      parent: "object",
      creator: "object"
    }}

    it_behaves_like 'an Elasticsearch::Model'
    it_behaves_like 'an Elasticsearch index mapping model' do
      it {
        #parent
        expect(subject[:folder][:properties][:parent]).to have_key :properties
        expect(subject[:folder][:properties][:parent][:properties]).to have_key :id
        expect(subject[:folder][:properties][:parent][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:parent][:properties]).to have_key :name
        expect(subject[:folder][:properties][:parent][:properties][:name][:type]).to eq "string"

        #creator
        expect(subject[:folder][:properties][:creator]).to have_key :properties
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :id
        expect(subject[:folder][:properties][:creator][:properties][:id][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :username
        expect(subject[:folder][:properties][:creator][:properties][:username][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :email
        expect(subject[:folder][:properties][:creator][:properties][:email][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :first_name
        expect(subject[:folder][:properties][:creator][:properties][:first_name][:type]).to eq "string"
        expect(subject[:folder][:properties][:creator][:properties]).to have_key :last_name
        expect(subject[:folder][:properties][:creator][:properties][:last_name][:type]).to eq "string"
      }
    end
  end
end
