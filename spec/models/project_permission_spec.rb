require 'rails_helper'

RSpec.describe ProjectPermission, type: :model do
  subject {
    FactoryBot.build(:project_permission, :project_admin)
  }
  let(:new_auth_role) {
    FactoryBot.create(:auth_role, :project_viewer)
  }
  let(:change_subject) {
    subject.auth_role = new_auth_role
    true
  }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it 'should belong to a user' do
      should belong_to :user
    end

    it 'should belong to a project' do
      should belong_to :project
    end

    it 'should have many a project permissions' do
      should have_many(:project_permissions).through(:project)
    end

    it 'should belong to an auth_role' do
      should belong_to :auth_role
    end
  end

  describe 'validations' do
    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a user_id unique to the project' do
      should validate_uniqueness_of(:user_id).scoped_to(:project_id).case_insensitive
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have an auth_role_id' do
      should validate_presence_of(:auth_role_id)
    end
  end

  it_behaves_like 'a ProjectUpdater'
end
