require 'rails_helper'

RSpec.describe SystemPermission, type: :model do
  describe 'associations' do
    it 'should have a user' do
      should belong_to(:user)
    end

    it 'should have an auth_role' do
      should belong_to(:auth_role)
    end
  end

  describe 'validations' do
    subject { FactoryGirl.create(:system_permission) }

    it 'should have a unique user_id' do
      should validate_presence_of(:user_id)
      should validate_uniqueness_of(:user_id)
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end
  end

  describe 'serialization' do
  end
end
