require 'rails_helper'
require 'shoulda-matchers'

RSpec.describe Membership, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:membership)}

    it 'should have a user_id' do
      should validate_presence_of(:user_id)
    end

    it 'should have a project_id' do
      should validate_presence_of(:project_id)
    end
  end

  describe 'serialization' do
    subject {FactoryGirl.create(:membership)}

    it 'should serialize to json' do
      serializer = MembershipSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('project')
      expect(parsed_json).to have_key('user')
      expect(parsed_json).to have_key('project_roles')
      expect(parsed_json['id']).to eq(subject.id)
      expect(parsed_json['project']).to eq({'id' => subject.project.uuid})
      expect(parsed_json['user']).to eq({'id' => subject.user.uuid,
                                         'full_name' => subject.user.display_name,
                                         'email' => subject.user.email})
      expect(parsed_json['project_roles']).to eq(Array.new)
    end
  end
end
