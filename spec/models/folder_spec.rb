require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:root_folder) { FactoryGirl.create(:folder, :root) }
  let(:grand_child_folder) { FactoryGirl.create(:folder, parent: child_folder) }
  let(:grand_child_file) { FactoryGirl.create(:data_file, parent: child_folder) }
  let(:invalid_file) { FactoryGirl.create(:data_file, :invalid, parent: child_folder) }
  let(:is_logically_deleted) { true }
  let(:project) { subject.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_folder) { FactoryGirl.create(:folder, project: other_project) }

  it_behaves_like 'an audited model' do
    it_behaves_like 'with a serialized audit'
  end

  it_behaves_like 'a kind'

  describe 'associations' do
    it 'should be part of a project' do
      should belong_to(:project)
    end

    it 'should have a parent' do
      should belong_to(:parent)
    end

    it 'should have many project permissions' do
      should have_many(:project_permissions).through(:project)
    end
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
end
