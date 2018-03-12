require 'rails_helper'

describe ProjectPermissionPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:other_users_project_permission) { FactoryBot.create(:project_permission, project: project_permission.project) }
  let(:other_project_permission) { FactoryBot.create(:project_permission) }

  it_behaves_like 'system_permission can access', :other_users_project_permission
  it_behaves_like 'system_permission can access', :other_project_permission

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :project_permission
  it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:create?], on: :project_permission

  context 'when another :manage_project_permissions exists' do
    let!(:another_project_admin) { FactoryBot.create(:project_permission, :project_admin, project: project_permission.project) }

    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :project_permission
    it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:create?, :update?, :destroy?], on: :project_permission
  end

  context 'when a non manager exists' do
    let(:non_admin_role) { FactoryBot.create(:auth_role, without_permissions: [:manage_project_permissions]) }
    let!(:a_non_admin) { FactoryBot.create(:project_permission, auth_role: non_admin_role, project: project_permission.project) }

    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :project_permission
    it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:create?], on: :project_permission
  end

  context 'when a :manage_project_permissions exists in different project' do
    let!(:another_project_admin) { FactoryBot.create(:project_permission, :project_admin) }

    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :project_permission
    it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:create?], on: :project_permission
  end

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :other_users_project_permission
  it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:create?, :update?, :destroy?], on: :other_users_project_permission

  it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :other_project_permission
  it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [], on: :other_project_permission

  it_behaves_like 'a user without project_permission', [:view_project, :manage_project_permissions], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_users_project_permission
  it_behaves_like 'a user without project_permission', [:view_project, :manage_project_permissions], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_project_permission

  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(other_users_project_permission) }
      it { expect(resolved_scope).not_to include(other_project_permission) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, other_users_project_permission) }
      it { is_expected.not_to permit(user, other_project_permission) }
    end
  end
end
