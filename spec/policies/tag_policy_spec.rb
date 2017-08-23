require 'rails_helper'

describe TagPolicy do
  include_context 'policy declarations'

  let(:tag) { FactoryGirl.create(:tag, taggable: taggable_object) }

  context 'with taggable DataFile' do
    let(:taggable_object) { FactoryGirl.create(:data_file, project: project_permission.project) }
    let(:other_tag) { FactoryGirl.create(:tag) }
    let(:auth_role) { FactoryGirl.create(:auth_role) }
    let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }

    it_behaves_like 'system_permission can access', :tag
    it_behaves_like 'system_permission can access', :other_tag

    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], on: :tag
    it_behaves_like 'a user with project_permission', :update_file, allows: [:create?, :update?, :destroy?], on: :tag

    it_behaves_like 'a user with project_permission', :view_project, allows: [], on: :other_tag
    it_behaves_like 'a user with project_permission', :update_file, allows: [], on: :other_tag

    it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :tag
    it_behaves_like 'a user without project_permission', [:view_project, :update_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_tag

    context 'when user does not have project_permission' do
      let(:user) { FactoryGirl.create(:user) }

      describe '.scope' do
        it { expect(resolved_scope).not_to include(tag) }
        it { expect(resolved_scope).not_to include(other_tag) }
      end
      permissions :index?, :show?, :create?, :update?, :destroy? do
        it { is_expected.not_to permit(user, tag) }
        it { is_expected.not_to permit(user, other_tag) }
      end
    end
  end

  context 'with taggable Activity' do
    let(:taggable_object) { FactoryGirl.create(:activity) }
    let(:other_tag) { FactoryGirl.create(:tag, taggable: other_activity) }
    let(:other_activity) { FactoryGirl.create(:activity) }
    let(:creator) { taggable_object.creator }

    let(:auth_role) { FactoryGirl.create(:auth_role, permissions: [:view_project]) }
    let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
    let(:project_viewer) { project_permission.user }
    let(:visible_file_version) {
      FactoryGirl.create(:data_file,
                         project: project_permission.project).current_file_version
    }
    let(:visible_related_activity) {
      FactoryGirl.create(:used_prov_relation,
                         relatable_to: visible_file_version).relatable_from
    }
    let(:related_tag) { FactoryGirl.create(:tag, taggable: visible_related_activity) }

    it_behaves_like 'system_permission can access', :tag
    it_behaves_like 'system_permission can access', :other_tag

    [:index?, :show?].each do |permission|
      context "#{permission} permission" do
        it { expect( described_class.new(creator, tag).send(permission) ).to eq(ActivityPolicy.new(creator, taggable_object).show?)}
        it { expect( described_class.new(creator, other_tag).send(permission) ).to eq(ActivityPolicy.new(creator, other_activity).show?)}
        it { expect( described_class.new(project_viewer, related_tag).send(permission) ).to eq(ActivityPolicy.new(project_viewer, visible_related_activity).show?)}
      end
    end
    [:create?, :update?, :destroy?].each do |permission|
      context "#{permission} permission" do
        it { expect( described_class.new(creator, tag).send(permission) ).to eq(ActivityPolicy.new(creator, taggable_object).update?)}
        it { expect( described_class.new(creator, other_tag).send(permission) ).to eq(ActivityPolicy.new(creator, other_activity).update?)}
        it { expect( described_class.new(project_viewer, related_tag).send(permission) ).to eq(ActivityPolicy.new(project_viewer, visible_related_activity).update?)}
      end
    end
  end
end
