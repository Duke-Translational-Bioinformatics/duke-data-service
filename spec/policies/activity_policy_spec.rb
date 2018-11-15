require 'rails_helper'

describe ActivityPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role, permissions: [:view_project]) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:user) { project_permission.user }
  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:activity) { FactoryBot.create(:activity, creator: user) }
  let(:other_activity) { FactoryBot.create(:activity) }

  it_behaves_like 'system_permission can access', :activity
  it_behaves_like 'system_permission can access', :other_activity
  it_behaves_like 'a policy for', :user, on: :other_activity, allows: [:index?, :create?]

  context 'authenticated user' do
    let(:visible_used_file_version) { FactoryBot.create(:file_version, data_file: data_file) }
    let(:visible_used_prov_relation) { FactoryBot.create(:used_prov_relation,
      relatable_to: visible_used_file_version)
    }
    let(:invisible_used_prov_relation) { FactoryBot.create(:used_prov_relation) }
    let(:visible_using_activity) { visible_used_prov_relation.relatable_from }
    let(:invisible_using_activity) { invisible_used_prov_relation.relatable_from }

    let(:visible_generated_file_version) { FactoryBot.create(:file_version, data_file: data_file) }
    let(:visible_generated_prov_relation) { FactoryBot.create(:generated_by_activity_prov_relation,
      relatable_from: visible_generated_file_version)
    }
    let(:invisible_generated_prov_relation) { FactoryBot.create(:generated_by_activity_prov_relation) }
    let(:visible_generating_activity) { visible_generated_prov_relation.relatable_to }
    let(:invisible_generating_activity) { invisible_generated_prov_relation.relatable_to }

    let(:visible_invalidated_file_version) { FactoryBot.create(:file_version, :deleted, data_file: data_file) }
    let(:visible_invalidated_prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation,
      relatable_from: visible_invalidated_file_version)
    }
    let(:invisible_invalidated_prov_relation) { FactoryBot.create(:invalidated_by_activity_prov_relation) }
    let(:visible_invalidating_activity) { visible_invalidated_prov_relation.relatable_to }
    let(:invisible_invalidating_activity) { invisible_invalidated_prov_relation.relatable_to }

    describe '.scope' do
      it { expect(resolved_scope).to include(activity) }
      it { expect(resolved_scope).to include(visible_using_activity) }
      it { expect(resolved_scope).to include(visible_generating_activity) }
      it { expect(resolved_scope).to include(visible_invalidating_activity) }

      it { expect(resolved_scope).not_to include(other_activity) }
      it { expect(resolved_scope).not_to include(invisible_using_activity) }
      it { expect(resolved_scope).not_to include(invisible_generating_activity) }
      it { expect(resolved_scope).not_to include(invisible_invalidating_activity) }
    end

    context 'who created an activity' do
      let(:built_activity) { FactoryBot.build(:activity, creator: user) }
      it_behaves_like 'a policy for', :user, on: :activity, allows: [:scope, :index?, :create?, :show?, :update?, :destroy?]
      it_behaves_like 'a policy for', :user, on: :built_activity, allows: [:index?, :create?, :show?, :update?, :destroy?]
    end

    context 'who did not create an activity' do
      context 'referencing an entity visible to the user' do
        it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :create?, :show?], on: :visible_using_activity
        it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :create?, :show?], on: :visible_generating_activity
        it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :create?, :show?], on: :visible_invalidating_activity
      end

      context 'referencing an entity not visibile to the user' do
        it_behaves_like 'a policy for', :user, on: :other_activity, allows: [:index?, :create?]
        it_behaves_like 'a policy for', :user, on: :invisible_using_activity, allows: [:index?, :create?]
        it_behaves_like 'a policy for', :user, on: :invisible_generating_activity, allows: [:index?, :create?]
        it_behaves_like 'a policy for', :user, on: :invisible_invalidating_activity, allows: [:index?, :create?]
      end
    end
  end
end
