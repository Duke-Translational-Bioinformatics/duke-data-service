require 'rails_helper'

RSpec.describe SystemPermission, type: :model do
  subject { FactoryBot.build(:system_permission) }
  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:system_auth_role) { FactoryBot.create(:auth_role, :system) }

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
      should validate_uniqueness_of(:user_id).case_insensitive
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end

    it 'should only allow auth_role with system context' do
      should allow_value(system_auth_role).for(:auth_role)
      should_not allow_value(auth_role).for(:auth_role)
    end
  end
end
