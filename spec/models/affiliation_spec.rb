require 'rails_helper'

RSpec.describe Affiliation, type: :model do
  subject { FactoryBot.build(:affiliation) }

  it_behaves_like 'an audited model'
  describe 'associations' do
    it 'should belong_to a project' do
      should belong_to(:project)
    end

    it 'should belong_to a user' do
      should belong_to(:user)
    end

    it 'should belong_to a project_role' do
      should belong_to(:project_role)
    end

    it 'should have many project permissions' do
      should have_many(:project_permissions).through(:project)
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

    it 'should have a project_role_id' do
      should validate_presence_of(:project_role_id)
    end
  end

  describe '#update_project_etag' do
    let(:created_object) { FactoryBot.build(:affiliation) }

    let(:user) { FactoryBot.create(:user) }
    let(:object_unchanged) {
      FactoryBot.create(:affiliation, user: user)
    }
    let(:new_project_role) { FactoryBot.create(:project_role) }
    let(:object_to_update) {
      FactoryBot.create(:affiliation, user: user)
    }
    let(:object_to_destroy) {
      FactoryBot.create(:affiliation)
    }

    before do
      unchanged_project_role = object_unchanged.project_role
      object_unchanged.project_role = unchanged_project_role
      object_to_update.project_role = new_project_role
    end

    it_behaves_like 'a parent project etag update',
      :created_object,
      :object_unchanged,
      :object_to_update,
      :object_to_destroy
  end
end
