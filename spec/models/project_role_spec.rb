require 'rails_helper'

RSpec.describe ProjectRole, type: :model do
  subject {FactoryGirl.create(:project_role)}

  it 'should have id as primary key' do
    expect(ProjectRole.primary_key).to eq('id')
  end

  describe 'associations' do
    it 'should have many affiliations' do
      should have_many(:affiliations)
    end
  end

  describe 'validations' do
    it 'should have a unique id' do
      should validate_presence_of(:id)
      should validate_uniqueness_of(:id)
    end

    it 'should have a name' do
      should validate_presence_of(:name)
    end

    it 'should have a description' do
      should validate_presence_of(:description)
    end
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = ProjectRoleSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('description')
      expect(parsed_json).to have_key('is_deprecated')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['description']).to eq(subject.description)
      expect(parsed_json['is_deprecated']).to eq(subject.is_deprecated)
    end
  end
end
