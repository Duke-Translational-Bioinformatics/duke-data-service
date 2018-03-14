require 'rails_helper'

describe UserPolicy do
  include_context 'policy declarations'

  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:new_user) { FactoryBot.build(:user) }

  describe '.scope' do
    it { expect(resolved_scope).to include(other_user) }
    it { expect(resolved_scope).to include(user) }
  end

  it_behaves_like 'system_permission can access', :user
  it_behaves_like 'system_permission can access', :other_user
  it_behaves_like 'a policy for', :user, on: :user, allows: [:scope, :index?, :show?, :create?, :update?, :destroy?]
  it_behaves_like 'a policy for', :user, on: :other_user, allows: [:scope, :index?, :create?, :show?]
  it_behaves_like 'a policy for', :user, on: :new_user, allows: [:index?, :show?, :create?]
end
