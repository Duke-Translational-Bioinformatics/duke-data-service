require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Project, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:project)}

    it 'should have a unique project name' do
      should validate_presence_of(:name)
      should validate_uniqueness_of(:name)
    end

    it 'should have a description' do
      should validate_presence_of(:description)
    end

    it 'should have a creator_id' do
      should validate_presence_of(:creator_id)
    end
  end

  describe 'serialization' do
    subject {FactoryGirl.create(:project)}

    it 'should serialize to json' do
      serializer = ProjectSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('description')
      expect(parsed_json).to have_key('is_deleted')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['description']).to eq(subject.description)
      expect(parsed_json['is_deleted']).to eq(subject.is_deleted)
    end
  end
end
