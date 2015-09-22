require 'rails_helper'

RSpec.describe Folder, type: :model do
  subject { FactoryGirl.create(:folder) }

  describe 'associations' do

    it 'should be part of a project' do
      should belong_to(:project)
    end

    it 'should have a folder' do
      should belong_to(:folder)
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
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = FolderSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('parent')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('project')
      expect(parsed_json).to have_key('is_deleted')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['parent']['id']).to eq(subject.folder_id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
    end
  end

  describe 'instance methods' do
    it 'should support virtual_path' do
      expect(subject).to respond_to(:virtual_path)
      if subject.folder
        expect(subject.virtual_path).to eq([
          subject.folder.virtual_path,
          subject.name
        ].join('/'))
      else
        expect(subject.virtual_path).to eq("/#{subject.name}")
      end
    end
  end
end
