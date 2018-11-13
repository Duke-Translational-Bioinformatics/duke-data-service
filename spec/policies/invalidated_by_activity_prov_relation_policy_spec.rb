require 'rails_helper'

describe InvalidatedByActivityProvRelationPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role, permissions: [:view_project].flatten) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:user) { project_permission.user }

  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:users_file_version) { FactoryBot.create(:file_version, :deleted, data_file: data_file) }
  let(:users_activity) { FactoryBot.create(:activity, creator: user) }

  let(:other_users_file_version) { FactoryBot.create(:file_version, :deleted) }
  let(:other_users_activity) { FactoryBot.create(:activity, creator: other_users_file_version.data_file.upload.creator )}
  let(:other_file_version_creator) { other_users_file_version.data_file.upload.creator }

  context 'destroy' do
    let(:prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
      relatable_to: users_activity,
      creator: user,
      relatable_from: users_file_version)
    }
    let(:other_prov_relation) {
      FactoryBot.create(:invalidated_by_activity_prov_relation)
    }
    it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :destroy?]
    it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: []
  end

  context 'from file_version deletable by user' do
    context 'to users activity' do
      let(:prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
        relatable_to: users_activity,
        creator: user,
        relatable_from: users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :delete_file,  on: :prov_relation, allows: [:scope, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?, :destroy?]
    end

    context 'to other users activity' do
      let(:prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
        relatable_to: other_users_activity,
        creator: other_users_activity.creator,
        relatable_from: users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?]
    end
  end

  context 'from file_version not deletable to user' do
    context 'to users activity' do
      let(:prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
        relatable_to: users_activity,
        relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :delete_file, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end

    context 'to other users activity' do
      let(:prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
        relatable_to: other_users_activity,
        relatable_from: other_users_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :delete_file, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end
  end
end
