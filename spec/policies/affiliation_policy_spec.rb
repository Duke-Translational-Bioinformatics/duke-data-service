require 'rails_helper'

describe AffiliationPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:affiliation) { FactoryGirl.create(:affiliation, project: project_permission.project) }
  let(:other_affiliation) { FactoryGirl.create(:affiliation) }

  it_behaves_like 'system_permission can access', :affiliation
  it_behaves_like 'system_permission can access', :other_affiliation

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    context 'without view_project, update_project' do
      let(:auth_role) { FactoryGirl.create(:auth_role, without_permissions: %w(view_project update_project)) }
      describe '.scope' do
        it { expect(resolved_scope).not_to include(affiliation) }
        it { expect(resolved_scope).not_to include(other_affiliation) }
      end
      permissions :show?, :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, affiliation) }
        it { is_expected.not_to permit(user, other_affiliation) }
      end
    end

    context 'with view_project permission' do
      let(:auth_role) { FactoryGirl.create(:auth_role, permissions: %w(view_project)) }
      describe '.scope' do
        it { expect(resolved_scope).to include(affiliation) }
        it { expect(resolved_scope).not_to include(other_affiliation) }
      end
      permissions :show? do
        it { is_expected.to permit(user, affiliation) }
        it { is_expected.not_to permit(user, other_affiliation) }
      end
      permissions :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, affiliation) }
        it { is_expected.not_to permit(user, other_affiliation) }
      end
    end

    context 'with update_project permission' do
      let(:auth_role) { FactoryGirl.create(:auth_role, permissions: %w(update_project)) }
      describe '.scope' do
        it { expect(resolved_scope).not_to include(affiliation) }
        it { expect(resolved_scope).not_to include(other_affiliation) }
      end
      permissions :show? do
        it { is_expected.not_to permit(user, affiliation) }
        it { is_expected.not_to permit(user, other_affiliation) }
      end
      permissions :create?, :update?, :destroy? do
        it { is_expected.to permit(user, affiliation) }
        it { is_expected.not_to permit(user, other_affiliation) }
      end
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(affiliation) }
      it { expect(resolved_scope).not_to include(other_affiliation) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, affiliation) }
      it { is_expected.not_to permit(user, other_affiliation) }
    end
  end

  context 'when user has system_permission' do
    let(:user) { FactoryGirl.create(:system_permission).user }

    describe '.scope' do
      it { expect(resolved_scope).to include(affiliation) }
      it { expect(resolved_scope).to include(other_affiliation) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, affiliation) }
      it { is_expected.to permit(user, other_affiliation) }
    end
  end
end
