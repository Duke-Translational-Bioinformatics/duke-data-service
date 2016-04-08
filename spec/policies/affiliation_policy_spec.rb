require 'rails_helper'

describe AffiliationPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:affiliation) { FactoryGirl.create(:affiliation, project: project_permission.project) }
  let(:other_affiliation) { FactoryGirl.create(:affiliation) }

  it_behaves_like 'system_permission can access', :affiliation
  it_behaves_like 'system_permission can access', :other_affiliation

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :affiliation
  it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :other_affiliation

  it_behaves_like 'a user with project_permission', :update_project, allows: [:create?, :update?, :destroy?], on: :affiliation
  it_behaves_like 'a user with project_permission', :update_project, allows: [], on: :other_affiliation

  it_behaves_like 'a user without project_permission', [:view_project, :update_project], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :affiliation
  it_behaves_like 'a user without project_permission', [:view_project, :update_project], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_affiliation

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(affiliation) }
      it { expect(resolved_scope).not_to include(other_affiliation) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, affiliation) }
      it { is_expected.not_to permit(user, other_affiliation) }
    end
  end
end
