require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { child_folder }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:resource_class) { Folder }
  let(:resource_serializer) { FolderSerializer }
  let!(:resource) { subject }
  let(:is_logically_deleted) { true }

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

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    context 'with children' do
      subject { child_folder.parent }

      it 'should not allow is_deleted to be set to true' do
        should_not allow_value(true).for(:is_deleted)
        should allow_value(false).for(:is_deleted)
      end
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
      expect(parsed_json).to have_key('is_deleted')

      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['parent']['kind']).to eq(subject.parent.kind)
      expect(parsed_json['parent']['id']).to eq(subject.parent.id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
    end

    context 'without a parent' do
      subject { FactoryGirl.create(:folder, :root) }

      it 'should have expected keys and values' do
        expect(parsed_json).to have_key('parent')
        expect(parsed_json['parent']).to have_key('kind')
        expect(parsed_json['parent']).to have_key('id')

        expect(parsed_json['parent']['kind']).to eq(subject.project.kind)
        expect(parsed_json['parent']['id']).to eq(subject.project.id)
    end
    end
  end

  describe 'instance methods' do
    it 'should support virtual_path' do
      expect(subject).to respond_to(:virtual_path)
      if subject.parent
        expect(subject.virtual_path).to eq([
          subject.parent.virtual_path,
          subject.name
        ].join('/'))
      else
        expect(subject.virtual_path).to eq("/#{subject.name}")
      end
    end
  end
end
