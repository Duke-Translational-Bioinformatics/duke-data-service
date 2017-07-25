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
    let(:user) { taggable_object.creator }
    let(:tag_policy) { TagPolicy.new(user, tag) }
    let(:activity_policy) { ActivityPolicy.new(user, tag) }

    it_behaves_like 'system_permission can access', :tag
    it_behaves_like 'system_permission can access', :other_tag

    [:index?, :show?].each do |permission|
      context "#{permission} permission" do
        it { expect( TagPolicy.new(user, tag).send(permission) ).to eq(ActivityPolicy.new(user, taggable_object).show?)}
        it { expect( TagPolicy.new(user, other_tag).send(permission) ).to eq(ActivityPolicy.new(user, other_activity).show?)}
      end
    end
    [:create?, :update?, :destroy?].each do |permission|
      context "#{permission} permission" do
        it { expect( TagPolicy.new(user, tag).send(permission) ).to eq(ActivityPolicy.new(user, taggable_object).update?)}
        it { expect( TagPolicy.new(user, other_tag).send(permission) ).to eq(ActivityPolicy.new(user, other_activity).update?)}
      end
    end
  end
end
