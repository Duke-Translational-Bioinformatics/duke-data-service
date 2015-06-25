require 'rails_helper'
require 'shoulda-matchers'
require 'jwt'

RSpec.describe User, type: :model do
  let(:role_1) {FactoryGirl.create(:auth_role)}
  let(:role_2) {FactoryGirl.create(:auth_role)}
  describe 'associations' do
    subject {FactoryGirl.create(:user)}

    it 'should have_many user_authentication_services' do
      should have_many :user_authentication_services
    end
  end

  describe 'validations' do
    subject {FactoryGirl.create(:user)}

    it 'should only allow auth_role_ids that exist' do
      should allow_value([role_1.text_id]).for(:auth_role_ids)
      should allow_value([]).for(:auth_role_ids)
      should_not allow_value(['foo']).for(:auth_role_ids)
    end
  end

  describe 'authorization roles' do
    subject {FactoryGirl.create(:user, :with_auth_role)}

    it 'should have an auth_roles method that returns AuthRole objects' do
      expect(subject).to respond_to(:auth_roles)
      expect(subject.auth_roles).to be_a Array
      subject.auth_role_ids.each do |role_id|
        role = AuthRole.where(text_id: role_id).first
        expect(subject.auth_roles).to include(role)
      end
    end

    it 'should have an auth_roles= method' do
      expect(subject).to respond_to(:auth_roles=)
      new_role_ids = [ role_1.text_id, role_2.text_id ]
      subject.auth_roles = new_role_ids
      expect(subject.auth_role_ids).to eq(new_role_ids)
    end
  end

  describe 'serialization' do
    subject {FactoryGirl.create(:user)}

    it 'should serialize to json' do
      serializer = UserSerializer.new subject
      payload = serializer.to_json
      expect(payload).to be
      parsed_json = JSON.parse(payload)
      expect(parsed_json).to have_key('id')
      expect(parsed_json).to have_key('name')
      expect(parsed_json).to have_key('email')
      expect(parsed_json['id']).to eq(subject.uuid)
      expect(parsed_json['name']).to eq(subject.name)
      expect(parsed_json['email']).to eq(subject.email)
    end
  end
end
