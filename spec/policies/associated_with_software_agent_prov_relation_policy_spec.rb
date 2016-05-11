require 'rails_helper'

describe AssociatedWithSoftwareAgentProvRelationPolicy do
  include_context 'policy declarations'

  let(:users_activity) { FactoryGirl.create(:activity) }
  let(:other_users_activity) { FactoryGirl.create(:activity) }
  let(:authenticated_user) { users_activity.creator }
  let(:other_user) { other_users_activity.creator }
  let(:users_sa) { FactoryGirl.create(:software_agent, creator: user) }
  let(:other_users_sa) { FactoryGirl.create(:software_agent, creator: other_user) }

  context 'activity created by user' do
    context 'with a software agent that they created' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
        relatable_from: users_sa,
        relatable_to: users_activity)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [:show?, :create?, :destroy?], denies: [:index?, :update?]
    end

    context 'with a software agent created by another user' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
        relatable_from: other_users_sa,
        relatable_to: users_activity)
       }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [:show?, :create?, :destroy?], denies: [:index?, :update?]
    end
  end

  context 'activity created by other user' do
    context 'with a software_agent created by the user' do
      let(:prov_relation) {
        FactoryGirl.create(:associated_with_software_agent_prov_relation,
          relatable_from: users_sa,
          relatable_to: other_users_activity)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
    end

    context 'with a software_agent created by other user' do
      let(:prov_relation) {
        FactoryGirl.create(:associated_with_software_agent_prov_relation,
          relatable_from: other_users_sa,
          relatable_to: other_users_activity)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
      it_behaves_like 'a policy for', :authenticated_user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
    end
  end
end
