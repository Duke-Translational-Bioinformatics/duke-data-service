require 'rails_helper'

RSpec.describe Project, type: :model do
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
    let!(:auth_role) { FactoryGirl.create(:auth_role, id: 'project_admin') }
    it 'should give the project creator a project_admin permission' do
      expect(AuthRole.where(id: 'project_admin').count).to eq(1)
      expect {
        expect(subject).to be_persisted
      }.to change{ProjectPermission.count}.by(1)
      expect(subject.project_permissions.count).to eq(1)
      permission = subject.project_permissions.first
      expect(permission).to be_persisted
      expect(permission.auth_role).to eq(auth_role)
      expect(permission.user).to eq(subject.creator)
    end

    it 'should fail gracefullly if project_admin AuthRole does not exist' do
      auth_role.destroy
      expect(AuthRole.where(id: 'project_admin').count).to eq(0)
      expect {
        expect(subject).to be_persisted
      }.to change{ProjectPermission.count}.by(0)
      expect(subject.project_permissions.count).to eq(0)
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
