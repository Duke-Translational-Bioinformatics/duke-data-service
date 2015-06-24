require 'rails_helper'
require 'shoulda-matchers'
require 'jwt'

RSpec.describe User, type: :model do
  describe 'associations' do
    subject {FactoryGirl.create(:user)}

    it 'should have_many user_authentication_services' do
      should have_many :user_authentication_services
    end
  end

  describe 'authorization roles' do
    subject {FactoryGirl.create(:user, :system_admin)}

    it 'should have an auth_roles method' do
      expect(subject).to respond_to(:auth_roles)
      expect(subject.auth_roles).to eq(subject.auth_role_ids)
    end

    it 'should have an auth_roles= method' do
      expect(subject).to respond_to(:auth_roles=)
      new_role_ids = ['foo', 'bar']
      subject.auth_roles = new_role_ids
      expect(subject.auth_role_ids).to eq(new_role_ids)
    end
  end
end
