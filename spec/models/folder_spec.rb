require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Folder, type: :model do
  subject { FactoryGirl.create(:folder) }

  describe 'associations' do

    it 'should be part of a project' do
      should belong_to(:project)
    end

    it 'should have a parent' do
      should belong_to(:parent)
    end
  end

  describe 'validations' do

    it 'should have a name' do
      should validate_presence_of(:name)
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
      expect(parsed_json['parent']['id']).to eq(subject.parent_id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
    end
  end

end
