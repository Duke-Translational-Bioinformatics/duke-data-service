require 'rails_helper'

describe AssociatedWithUserProvRelationPolicy do
  include_context 'policy declarations'

  let(:users_activity) { FactoryGirl.create(:activity) }
  let(:other_users_activity) { FactoryGirl.create(:activity) }
  let(:authenticated_user) { users_activity.creator }
  let(:other_activity_creator) { other_users_activity.creator }

  context 'activity created by user' do
    let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
      relatable_from: authenticated_user,
      relatable_to: users_activity)
    }
    it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
    it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [:show?, :create?, :destroy?], denies: [:index?, :update?]
  end

  context 'activity created by other user' do
    let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
      relatable_from: other_activity_creator,
      relatable_to: other_users_activity)
    }
    it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
    it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
  end
end
