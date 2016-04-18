require 'rails_helper'

describe SystemPermissionPolicy do
  include_context 'policy declarations'

  let(:system_permission) { FactoryGirl.create(:system_permission) }
  let(:other_system_permission) { FactoryGirl.create(:system_permission) }

  it_behaves_like 'system_permission can access', :system_permission
  it_behaves_like 'system_permission can access', :other_system_permission

  context 'when user does not have system_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(system_permission) }
      it { expect(resolved_scope).not_to include(other_system_permission) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, system_permission) }
      it { is_expected.not_to permit(user, other_system_permission) }
    end
  end
end
