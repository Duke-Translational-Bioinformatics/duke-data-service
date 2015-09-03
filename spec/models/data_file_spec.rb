require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe DataFile, type: :model do
  subject { FactoryGirl.create(:data_file) }

  describe 'associations' do

    it 'should be part of a project' do
      should belong_to(:project)
    end

    it 'should have a parent' do
      should belong_to(:parent)
    end

    it 'should be based on an upload' do
      should belong_to(:upload)
    end
  end

  describe 'validations' do

    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have a upload_id' do
      should validate_presence_of(:upload_id)
    end
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = DataFileSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('parent')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('project')
      expect(parsed_json).to have_key('virtual_path')
      expect(parsed_json).to have_key('is_deleted')
      expect(parsed_json).to have_key('upload')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['parent']['id']).to eq(subject.parent_id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['project']['id']).to eq(subject.project_id)
      expect(parsed_json['virtual_path']).to eq(subject.virtual_path)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
      expect(parsed_json['upload']['id']).to eq(subject.upload_id)
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
