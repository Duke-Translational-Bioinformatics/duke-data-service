require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:root_folder) { FactoryGirl.create(:folder, :root) }
  let(:grand_child_folder) { FactoryGirl.create(:folder, parent: child_folder) }
  let(:grand_child_file) { FactoryGirl.create(:data_file, parent: child_folder) }
  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { subject }
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
  end

  describe 'serialization' do
    let(:serializer) { FolderSerializer.new subject }
    let(:payload) { serializer.to_json }
    let(:parsed_json) { JSON.parse(payload) }
    it 'should serialize to json' do
      expect(payload).to be
      expect{parsed_json}.to_not raise_error
    end

    it 'should have expected keys and values' do
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('parent')
      expect(parsed_json['parent']).to have_key('kind')
      expect(parsed_json['parent']).to have_key('id')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('project')
      expect(parsed_json['project']).to have_key('id')
      expect(parsed_json).to have_key('ancestors')
      expect(parsed_json).to have_key('is_deleted')

      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['parent']['kind']).to eq(subject.parent.kind)
      expect(parsed_json['parent']['id']).to eq(subject.parent.id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
    end

    describe 'ancestors' do
      it 'should return the project and parent' do
        expect(subject.project).to be
        expect(subject.parent).to be
        expect(parsed_json['ancestors']).to eq [
          {
            'kind' => subject.project.kind,
            'id' => subject.project.id,
            'name' => subject.project.name
          },
          {
            'kind' => subject.parent.kind,
            'id' => subject.parent.id,
            'name' => subject.parent.name
          }
        ]
      end
    end

    context 'without a parent' do
      subject { root_folder }

      it 'should have expected keys and values' do
        expect(parsed_json).to have_key('parent')
        expect(parsed_json['parent']).to have_key('kind')
        expect(parsed_json['parent']).to have_key('id')

        expect(parsed_json['parent']['kind']).to eq(subject.project.kind)
        expect(parsed_json['parent']['id']).to eq(subject.project.id)
      end

      describe 'ancestors' do
        it 'should return the project' do
          expect(subject.project).to be
          expect(parsed_json['ancestors']).to eq [
            {
              'kind' => subject.project.kind,
              'id' => subject.project.id,
              'name' => subject.project.name }
          ]
        end
      end
    end
  end
end
