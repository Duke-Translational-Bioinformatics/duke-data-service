require 'rails_helper'

describe MetaTemplatePolicy do
  include_context 'policy declarations'

  let(:meta_template) { FactoryBot.create(:meta_template, templatable: templatable_object) }
  let(:other_meta_template) { FactoryBot.create(:meta_template) }


  context 'with templatable DataFile' do
    let(:templatable_object) { FactoryBot.create(:data_file, project: project_permission.project) }
    let(:auth_role) { FactoryBot.create(:auth_role) }
    let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
    it_behaves_like 'system_permission can access', :meta_template
    it_behaves_like 'system_permission can access', :other_meta_template

    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :meta_template
    it_behaves_like 'a user with project_permission', :update_file, allows: [:create?, :update?, :destroy?], on: :meta_template

    it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :other_meta_template
    it_behaves_like 'a user with project_permission', :update_file, allows: [], on: :other_meta_template

    it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :meta_template
    it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_meta_template

    context 'when user does not have project_permission' do
      let(:user) { FactoryBot.create(:user) }

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

  context 'with templatable Activity' do
    let(:templatable_object) { FactoryBot.create(:activity) }
    let(:other_meta_template) { FactoryBot.create(:meta_template, templatable: other_activity) }
    let(:other_activity) { FactoryBot.create(:activity) }
    let(:creator) { templatable_object.creator }

    let(:auth_role) { FactoryBot.create(:auth_role, permissions: [:view_project]) }
    let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
    let(:project_viewer) { project_permission.user }
    let(:visible_file_version) {
      FactoryBot.create(:data_file,
                         project: project_permission.project).current_file_version
    }
    let(:visible_related_activity) {
      FactoryBot.create(:used_prov_relation,
                         relatable_to: visible_file_version).relatable_from
    }
    let(:related_meta_template) { FactoryBot.create(:meta_template, templatable: visible_related_activity) }

    it_behaves_like 'system_permission can access', :meta_template
    it_behaves_like 'system_permission can access', :other_meta_template
    it_behaves_like 'system_permission can access', :related_meta_template

    [:index?, :show?].each do |permission|
      context "#{permission} permission" do
        it { expect( described_class.new(creator, meta_template).send(permission) ).to eq(ActivityPolicy.new(creator, templatable_object).show?)}
        it { expect( described_class.new(creator, other_meta_template).send(permission) ).to eq(ActivityPolicy.new(creator, other_activity).show?)}
        it { expect( described_class.new(project_viewer, related_meta_template).send(permission) ).to eq(ActivityPolicy.new(project_viewer, visible_related_activity).show?)}
      end
    end
    [:create?, :update?, :destroy?].each do |permission|
      context "#{permission} permission" do
        it { expect( described_class.new(creator, meta_template).send(permission) ).to eq(ActivityPolicy.new(creator, templatable_object).update?)}
        it { expect( described_class.new(creator, other_meta_template).send(permission) ).to eq(ActivityPolicy.new(creator, other_activity).update?)}
        it { expect( described_class.new(project_viewer, related_meta_template).send(permission) ).to eq(ActivityPolicy.new(project_viewer, visible_related_activity).update?)}
      end
    end
  end
end
