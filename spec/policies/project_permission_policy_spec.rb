require 'rails_helper'

describe ProjectPermissionPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:other_users_project_permission) { FactoryGirl.create(:project_permission, project: project_permission.project) }
  let(:other_project_permission) { FactoryGirl.create(:project_permission) }

  it_behaves_like 'system_permission can access', :other_users_project_permission
  it_behaves_like 'system_permission can access', :other_project_permission

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(other_users_project_permission) }
      it { expect(resolved_scope).not_to include(other_project_permission) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, other_users_project_permission) }
      it { is_expected.not_to permit(user, other_project_permission) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(other_users_project_permission) }
      it { expect(resolved_scope).not_to include(other_project_permission) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, other_users_project_permission) }
      it { is_expected.not_to permit(user, other_project_permission) }
    end
  end
end
