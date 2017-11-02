require 'rails_helper'

describe AssociatedWithProvRelationPolicy do
  include_context 'policy declarations'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob

  let(:users_activity) { FactoryGirl.create(:activity) }
  let(:other_users_activity) { FactoryGirl.create(:activity) }
  let(:user) { users_activity.creator }
  let(:other_activity_creator) { other_users_activity.creator }

  describe 'AssociatedWithSoftwareAgentProvRelationPolicy' do
    let(:other_user) { other_users_activity.creator }
    let(:users_sa) { FactoryGirl.create(:software_agent, creator: user) }
    let(:other_users_sa) { FactoryGirl.create(:software_agent, creator: other_user) }

    context 'inheritance' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
        relatable_from: users_sa,
        creator: user,
        relatable_to: users_activity)
      }
      subject { Pundit.policy(user, prov_relation) }

      it {
        is_expected.to be
        is_expected.to be_a AssociatedWithProvRelationPolicy
      }
    end

    context 'destroy' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
        relatable_from: users_sa,
        creator: user,
        relatable_to: users_activity)
      }
      let(:other_prov_relation) {
        FactoryGirl.create(:associated_with_software_agent_prov_relation)
      }
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: [], denies: [:show?, :create?, :index?, :update?, :destroy?]
    end

    context 'activity created by user' do
      context 'with a software agent that they created' do
        let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
          relatable_from: users_sa,
          relatable_to: users_activity)
        }
        it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?], denies: [:index?, :update?]
        it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?], denies: [:index?, :update?, :destroy?]
      end

      context 'with a software agent created by another user' do
        let(:prov_relation) { FactoryGirl.create(:associated_with_software_agent_prov_relation,
          relatable_from: other_users_sa,
          relatable_to: users_activity)
         }
        it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
        it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?]
      end
    end

    context 'activity created by other user' do
      context 'with a software_agent created by the user' do
        let(:prov_relation) {
          FactoryGirl.create(:associated_with_software_agent_prov_relation,
            relatable_from: users_sa,
            relatable_to: other_users_activity)
        }
        it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
        it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
      end

      context 'with a software_agent created by other user' do
        let(:prov_relation) {
          FactoryGirl.create(:associated_with_software_agent_prov_relation,
            relatable_from: other_users_sa,
            relatable_to: other_users_activity)
        }
        it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
        it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
      end
    end
  end

  describe 'AssociatedWithUserProvRelationPolicy' do

    context 'inheritance' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
        relatable_from: user,
        creator: user,
        relatable_to: users_activity)
      }
      subject { Pundit.policy(user, prov_relation) }

      it {
        is_expected.to be
        is_expected.to be_a AssociatedWithProvRelationPolicy
      }
    end

    context 'destroy' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
        relatable_from: user,
        creator: user,
        relatable_to: users_activity)
      }
      let(:other_prov_relation) {
        FactoryGirl.create(:associated_with_user_prov_relation)
      }
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: [], denies: [:show?, :create?, :index?, :update?, :destroy?]
    end

    context 'activity created by user' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
        relatable_from: user,
        relatable_to: users_activity)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?]
    end

    context 'activity created by other user' do
      let(:prov_relation) { FactoryGirl.create(:associated_with_user_prov_relation,
        relatable_from: other_activity_creator,
        relatable_to: other_users_activity)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [], denies: [:index?, :update?, :show?, :create?, :destroy?]
    end
  end
end
