require 'rails_helper'

describe MetaTemplatePolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:meta_template) { FactoryGirl.create(:meta_template, templatable: data_file) }
  let(:other_meta_template) { FactoryGirl.create(:meta_template) }


  it_behaves_like 'system_permission can access', :meta_template
  it_behaves_like 'system_permission can access', :other_meta_template

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :meta_template
  it_behaves_like 'a user with project_permission', :update_file, allows: [:create?, :update?, :destroy?], on: :meta_template

  it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :other_meta_template
  it_behaves_like 'a user with project_permission', :update_file, allows: [], on: :other_meta_template

  it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :meta_template
  it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_meta_template

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(meta_template) }
      it { expect(resolved_scope).not_to include(other_meta_template) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, meta_template) }
      it { is_expected.not_to permit(user, other_meta_template) }
    end
  end
end
