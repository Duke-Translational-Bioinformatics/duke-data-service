require 'rails_helper'

describe ActivityPolicy do
  include_context 'policy declarations'

  let(:activity) { FactoryGirl.create(:activity) }
  let(:other_activity) { FactoryGirl.create(:activity) }

  it_behaves_like 'system_permission can access', :activity
  it_behaves_like 'system_permission can access', :other_activity

  context 'authenticated user' do
    let(:user) { activity.creator }

    permissions :index?, :create? do
      it { is_expected.to permit(user, activity) }
      it { is_expected.to permit(user, other_activity) }
      it { is_expected.to permit(user, FactoryGirl.build(:project, creator: user)) }
    end

    describe '.scope' do
      it { expect(resolved_scope).to include(activity) }
      it { expect(resolved_scope).not_to include(other_activity) }
    end

    context 'who created an activity' do
      permissions :show?, :update?, :destroy? do
        it { is_expected.to permit(user, activity) }
      end
    end

    context 'who did not create an activity' do
      permissions :show?, :update?, :destroy? do
        it { is_expected.not_to permit(user, other_activity) }
      end
    end
  end
end
