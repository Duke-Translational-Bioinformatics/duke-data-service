require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Project, type: :model do
  let(:user) { FactoryGirl.create(:user) }
  subject { FactoryGirl.create(:project) }

  describe 'associations' do
    it 'should have many project permissions' do
      should have_many(:project_permissions)
    end

    it 'should have many storage folders' do
      should have_many(:storage_folders)
    end

    it 'should have many data_files' do
      should have_many(:data_files)
    end
    
    it 'should have a creator' do
      should belong_to(:creator)
    end

    it 'should have many uploads' do
      should have_many(:uploads)
    end

    it 'should have many affiliations' do
      should have_many(:affiliations)
    end
  end

  describe 'validations' do
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

  describe 'assign project admin' do
    let!(:auth_role) {FactoryGirl.create(:auth_role, {text_id: 'project_admin'})}
    it 'should give the project creator a project_admin permission' do
      expect(subject).to be_persisted
      updated_user = User.find(subject.creator_id)
      expect(updated_user.auth_role_ids).to be
      expect(updated_user.auth_role_ids).not_to eq('null')
      expect(updated_user.auth_role_ids).to eq(['project_admin'])
      expect(updated_user.auth_roles).to include(auth_role)
    end
  end

  describe 'serialization' do
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
