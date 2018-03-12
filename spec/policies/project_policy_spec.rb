require 'rails_helper'

describe ProjectPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:project) { project_permission.project }
  let(:other_project) { FactoryBot.create(:project) }
  let(:unsaved_project) { FactoryBot.build(:project) }

  it_behaves_like 'system_permission can access', :project
  it_behaves_like 'system_permission can access', :other_project

  it_behaves_like 'a user with project_permission', :view_project, allows: [:index?, :create?, :scope, :show?], on: :project
  it_behaves_like 'a user with project_permission', :update_project, allows: [:index?, :create?, :update?], on: :project
  it_behaves_like 'a user with project_permission', :delete_project, allows: [:index?, :create?, :destroy?], on: :project

  it_behaves_like 'a user with project_permission', :view_project, allows: [:index?, :create?], on: :other_project
  it_behaves_like 'a user with project_permission', :update_project, allows: [:index?, :create?], on: :other_project
  it_behaves_like 'a user with project_permission', :delete_project, allows: [:index?, :create?], on: :other_project

  it_behaves_like 'a user without project_permission', [:view_project, :update_project, :delete_project], denies: [:scope, :show?, :update?, :destroy?], on: :project
  it_behaves_like 'a user without project_permission', [:view_project, :update_project, :delete_project], denies: [:scope, :show?, :update?, :destroy?], on: :other_project

  context 'when user has system_permission' do
    let(:user) { FactoryBot.create(:system_permission).user }

    permissions :show?, :index?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, unsaved_project) }
    end
  end

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    permissions :index?, :create? do
      it { is_expected.to permit(user, project) }
      it { is_expected.to permit(user, other_project) }
      it { is_expected.to permit(user, unsaved_project) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(project) }
      it { expect(resolved_scope).not_to include(other_project) }
    end
    permissions :show?, :update?, :destroy? do
      it { is_expected.not_to permit(user, project) }
      it { is_expected.not_to permit(user, other_project) }
    end
    permissions :create? do
      it { is_expected.to permit(user, project) }
      it { is_expected.to permit(user, other_project) }
      it { is_expected.to permit(user, unsaved_project) }
    end
  end
end
