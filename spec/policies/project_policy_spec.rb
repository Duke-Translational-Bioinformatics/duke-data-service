require 'rails_helper'

describe ProjectPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:project) { project_permission.project }
  let(:other_project) { FactoryGirl.create(:project) }
  let(:unsaved_project) { FactoryGirl.build(:project) }

  it_behaves_like 'system_permission can access', :project
  it_behaves_like 'system_permission can access', :other_project

  context 'when user has system_permission' do
    let(:user) { FactoryGirl.create(:system_permission).user }

    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, unsaved_project) }
    end
  end

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(project) }
      it { expect(resolved_scope).not_to include(other_project) }
    end
    permissions :show?, :update?, :destroy? do
      it { is_expected.to permit(user, project) }
      it { is_expected.not_to permit(user, other_project) }
    end
    permissions :create? do
      it { is_expected.to permit(user, project) }
      it { is_expected.to permit(user, other_project) }
      it { is_expected.to permit(user, unsaved_project) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

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
