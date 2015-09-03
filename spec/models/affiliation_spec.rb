require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Affiliation, type: :model do
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
  end

  describe 'validations' do
    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end

    it 'should have a project_role_id' do
      should validate_presence_of(:project_role_id)
    end
  end

  describe 'serialization' do
    subject { FactoryGirl.create(:affiliation) }
    let(:user) {subject.user}
    let(:role) {subject.project_role}

    it 'should serialize to json' do
      serializer = AffiliationSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to eq({
        'project' => {
          'id' => subject.project_id
        },
        'user' => {
          'id' => user.id,
          'full_name' => user.display_name,
          'email' => user.email
        },
        'project_role' => {
          'id' => role.id,
          'name' => role.name
        }
      })
    end
  end
end
