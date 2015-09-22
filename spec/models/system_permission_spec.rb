require 'rails_helper'

RSpec.describe SystemPermission, type: :model do
  subject { FactoryGirl.create(:system_permission) }

  describe 'associations' do
    it 'should have a user' do
      should belong_to(:user)
    end

    it 'should have an auth_role' do
      should belong_to(:auth_role)
    end
  end

  describe 'validations' do

    it 'should have a unique user_id' do
      should validate_presence_of(:user_id)
      should validate_uniqueness_of(:user_id)
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end
  end

  describe 'serialization' do
    it 'should serialize to json' do
      serializer = SystemPermissionSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('user')
      expect(parsed_json).to have_key('auth_role')
      expect(parsed_json['user']).to eq({
        'id' => subject.user.id,
        'username' => subject.user.username,
        'full_name' => subject.user.display_name
      })
      expect(subject.auth_role).to be
      expect(parsed_json['auth_role']).to eq({
        'id' => subject.auth_role.id,
        'name' => subject.auth_role.name,
        'description' => subject.auth_role.description
      })
    end
  end
end
