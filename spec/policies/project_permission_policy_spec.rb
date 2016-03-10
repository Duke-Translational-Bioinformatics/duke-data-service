require 'rails_helper'

describe ProjectPermissionPolicy do
  include_context 'policy declarations'

  let(:permission) { FactoryGirl.create(:project_permission) }
  let(:project_permission) { FactoryGirl.create(:project_permission, project: permission.project) }
  let(:other_project_permission) { FactoryGirl.create(:project_permission) }

  it_behaves_like 'system_permission can access', :project_permission
  it_behaves_like 'system_permission can access', :other_project_permission

  context 'when user has project_permission' do
    let(:user) { permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(project_permission) }
      it { expect(resolved_scope).not_to include(other_project_permission) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, project_permission) }
      it { is_expected.not_to permit(user, other_project_permission) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(project_permission) }
      it { expect(resolved_scope).not_to include(other_project_permission) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, project_permission) }
      it { is_expected.not_to permit(user, other_project_permission) }
    end
  end
end
