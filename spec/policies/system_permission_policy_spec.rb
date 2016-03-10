require 'rails_helper'

describe SystemPermissionPolicy do
  let(:permission) { FactoryGirl.create(:system_permission) }
  let(:user) { permission.user }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:system_permission) { FactoryGirl.build(:system_permission) }
  let(:other_system_permission) { FactoryGirl.create(:system_permission) }
  
  let(:scope) { subject.new(user, system_permission).scope }
  let(:other_scope) { subject.new(other_user, system_permission).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns system_permissions with system permission' do
      expect(system_permission.save).to be_truthy
      expect(permission).to be_persisted
      expect(other_system_permission).to be_persisted
      expect(scope.all).to include(permission)
      expect(scope.all).to include(system_permission)
      expect(scope.all).to include(other_system_permission)
    end

    it 'does not return system_permissions without system permission' do
      expect(system_permission.save).to be_truthy
      expect(permission).to be_persisted
      expect(other_system_permission).to be_persisted
      expect(other_scope.all).not_to include(permission)
      expect(other_scope.all).not_to include(system_permission)
      expect(other_scope.all).not_to include(other_system_permission)
    end
  end

  permissions :show? do
    it 'denies access without system permission' do
      is_expected.not_to permit(other_user, system_permission)
      is_expected.not_to permit(other_user, other_system_permission)
    end

    it 'grants access with system permission' do
      is_expected.to permit(user, system_permission)
      is_expected.to permit(user, other_system_permission)
    end
  end

  permissions :create? do
    it 'denies access without system permission' do
      is_expected.not_to permit(other_user, system_permission)
      is_expected.not_to permit(other_user, other_system_permission)
    end

    it 'grants access with system permission' do
      is_expected.to permit(user, system_permission)
      is_expected.to permit(user, other_system_permission)
    end
  end

  permissions :update? do
    it 'denies access without system permission' do
      is_expected.not_to permit(other_user, system_permission)
      is_expected.not_to permit(other_user, other_system_permission)
    end

    it 'grants access with system permission' do
      is_expected.to permit(user, system_permission)
      is_expected.to permit(user, other_system_permission)
    end
  end

  permissions :destroy? do
    it 'denies access without system permission' do
      is_expected.not_to permit(other_user, system_permission)
      is_expected.not_to permit(other_user, other_system_permission)
    end

    it 'grants access with system permission' do
      is_expected.to permit(user, system_permission)
      is_expected.to permit(user, other_system_permission)
    end
  end
end
