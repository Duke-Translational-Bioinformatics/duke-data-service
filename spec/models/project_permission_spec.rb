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

    it 'should have many auth_roles' do
      should respond_to :auth_roles
      expect(subject.auth_roles).to be_a Array
      expect(subject.auth_roles).not_to be_empty
      expect(subject.auth_role_ids).not_to be_empty
      subject.auth_roles.each do |role|
        expect(role).to be_a AuthRole
        expect(subject.auth_role_ids).to include(role.text_id)
      end
    end

    it 'should have an auth_roles= method' do
      expect(subject).to respond_to(:auth_roles=)
      new_role_ids = roles.collect{|r| r.text_id}
      subject.auth_roles = new_role_ids
      expect(subject.auth_role_ids).to eq(new_role_ids)
    end
  end

  describe 'validations' do
    it 'should only allow auth_role_ids that exist' do
      should allow_value([roles.first.text_id]).for(:auth_role_ids)
      should_not allow_value(['foo']).for(:auth_role_ids)
    end

    it 'should allow an empty list for auth_role_ids' do
      should allow_value([]).for(:auth_role_ids)
    end

    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
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
      expect(parsed_json).to have_key('auth_roles')
      expect(parsed_json['user']).to eq({
        'id' => subject.user.id, 
        'full_name' => subject.user.display_name
      })
      expect(parsed_json['project']).to eq({'id' => subject.project.id})
      expect(parsed_json['auth_roles']).to be_a Array
    end
  end
end
