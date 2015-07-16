require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe ProjectPermission, type: :model do
  let(:roles) {FactoryGirl.create_list(:auth_role, 2)}
  subject {FactoryGirl.create(:project_permission)}
  describe 'associations' do
    it 'should belong to a user' do
      should belong_to :user
    end

    it 'should belong to a project' do
      should belong_to :project
    end

    it 'should belong to an auth_role' do
      should belong_to :auth_role
    end
  end

  describe 'validations' do
    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = ProjectPermissionSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('user')
      expect(parsed_json).to have_key('project')
      expect(parsed_json).to have_key('auth_role')
      expect(parsed_json['user']).to eq({
        'id' => subject.user.id, 
        'full_name' => subject.user.display_name
      })
      expect(subject.auth_role).to be
      expect(parsed_json['auth_role']).to eq({
        'id' => subject.auth_role.text_id,
        'name' => subject.auth_role.name,
        'description' => subject.auth_role.description
      })
      expect(parsed_json['project']).to eq({'id' => subject.project.id})
    end
  end
end
