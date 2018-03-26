require 'rails_helper'

describe ProjectTransferPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:project_transfer) { FactoryBot.create(:project_transfer, :with_to_users, project: project_permission.project) }
  let(:other_project_transfer) { FactoryBot.create(:project_transfer, :with_to_users) }
  let(:to_user) { FactoryBot.create(:project_transfer_user, project_transfer: project_transfer).to_user }

  it_behaves_like 'system_permission can access', :project_transfer
  it_behaves_like 'system_permission can access', :other_project_transfer

  it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [:scope, :create?, :index?, :show?, :destroy?], on: :project_transfer
  it_behaves_like 'a user with project_permission', :manage_project_permissions, allows: [], on: :other_project_transfer
  it_behaves_like 'a user without project_permission', :manage_project_permissions, denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :project_transfer
  it_behaves_like 'a user without project_permission', :manage_project_permissions, denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_project_transfer


  context 'when user is a transfer_project creator' do
    let(:user) { project_transfer.from_user }

    describe '.scope' do
      it { expect(resolved_scope).to include(project_transfer) }
      it { expect(resolved_scope).not_to include(other_project_transfer) }
    end
    permissions :index?, :show? do
      it { is_expected.to permit(user, project_transfer) }
      it { is_expected.not_to permit(user, other_project_transfer) }
    end
    permissions :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, project_transfer) }
      it { is_expected.not_to permit(user, other_project_transfer) }
    end
  end

  context 'when user is a project_transfer recipient' do
    let(:user) { to_user }

    describe '.scope' do
      it { expect(resolved_scope).to include(project_transfer) }
      it { expect(resolved_scope).not_to include(other_project_transfer) }
    end
    permissions :index?, :show?, :update? do
      it { is_expected.to permit(user, project_transfer) }
      it { is_expected.not_to permit(user, other_project_transfer) }
    end
    permissions :create?, :destroy? do
      it { is_expected.not_to permit(user, project_transfer) }
      it { is_expected.not_to permit(user, other_project_transfer) }
    end
  end
end
