require 'rails_helper'

describe DerivedFromFileVersionProvRelationPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role, permissions: [:view_project].flatten) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:user) { project_permission.user }

  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:visible_from_file_version) { FactoryBot.create(:file_version, data_file: data_file) }
  let(:visible_to_file_version) { FactoryBot.create(:file_version, data_file: data_file) }

  let(:invisible_from_file_version) { FactoryBot.create(:file_version) }
  let(:invisible_to_file_version) { FactoryBot.create(:file_version, data_file: invisible_from_file_version.data_file) }

  context 'destroy' do
    let(:prov_relation) { FactoryBot.create(:derived_from_file_version_prov_relation,
      relatable_to: visible_to_file_version,
      creator: user,
      relatable_from: visible_from_file_version)
    }
    let(:other_prov_relation) {
      FactoryBot.create(:derived_from_file_version_prov_relation)
    }
    it_behaves_like 'a policy for', :user, on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
    it_behaves_like 'a policy for', :user, on: :other_prov_relation, allows: []
  end

  context 'from file_version visible to user' do
    context 'to file_version visible to user' do
      let(:prov_relation) { FactoryBot.create(:derived_from_file_version_prov_relation,
        relatable_to: visible_to_file_version,
        creator: user,
        relatable_from: visible_from_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
    end

    context 'to file_version not visible to user' do
      let(:prov_relation) { FactoryBot.create(:derived_from_file_version_prov_relation,
        relatable_to: invisible_to_file_version,
        relatable_from: visible_from_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end
  end

  context 'from file_version not visible to user' do
    context 'to file_version visible to user' do
      let(:prov_relation) { FactoryBot.create(:derived_from_file_version_prov_relation,
        relatable_to: visible_to_file_version,
        relatable_from: invisible_from_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user with project_permission', :view_project,  on: :prov_relation, allows: [:scope, :show?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end

    context 'to file_version not visible to user' do
      let(:prov_relation) { FactoryBot.create(:derived_from_file_version_prov_relation,
        relatable_to: invisible_to_file_version,
        relatable_from: invisible_from_file_version)
      }
      it_behaves_like 'system_permission can access', :prov_relation, allows: [:scope, :show?, :create?, :destroy?]
      it_behaves_like 'a user without project_permission', :view_project, on: :prov_relation, denies: [:index?, :show?, :create?, :destroy?]
    end
  end
end
