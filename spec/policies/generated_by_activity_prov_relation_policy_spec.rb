require 'rails_helper'

describe GeneratedByActivityProvRelationPolicy do
  include_context 'policy declarations'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob

  let(:auth_role) { FactoryGirl.create(:auth_role, permissions: [:view_project].flatten) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:user) { project_permission.user }

  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:users_file_version) { FactoryGirl.create(:file_version, data_file: data_file) }
  let(:users_activity) { FactoryGirl.create(:activity, creator: user) }

  let(:other_users_file_version) { FactoryGirl.create(:file_version) }
  let(:other_users_activity) { FactoryGirl.create(:activity, creator: other_users_file_version.data_file.upload.creator )}
  let(:other_file_version_creator) { other_users_file_version.data_file.upload.creator }

  context 'destroy' do
    let(:prov_relation) { FactoryGirl.create(:generated_by_activity_prov_relation,
      relatable_to: users_activity,
      creator: user,
      relatable_from: users_file_version)
    }
    let(:other_prov_relation) {
      FactoryGirl.create(:generated_by_activity_prov_relation)
    }
    it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
    it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: []
  end

  context 'from file_version visible by user' do
    context 'to users activity' do
      let(:prov_relation) { FactoryGirl.create(:generated_by_activity_prov_relation,
        relatable_to: users_activity,
        creator: user,
        relatable_from: users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
    end

    context 'to other users activity' do
      let(:prov_relation) { FactoryGirl.create(:generated_by_activity_prov_relation,
        relatable_to: other_users_activity,
        creator: other_users_activity.creator,
        relatable_from: users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?]
    end
  end

  context 'from file_version not visible to user' do
    context 'to users activity' do
      let(:prov_relation) { FactoryGirl.create(:generated_by_activity_prov_relation,
        relatable_to: users_activity,
        relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end

    context 'to other users activity' do
      let(:prov_relation) { FactoryGirl.create(:generated_by_activity_prov_relation,
        relatable_to: other_users_activity,
        relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :prov_relation, allows: []
    end
  end
end
