require 'rails_helper'

describe FolderPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:folder) { FactoryGirl.create(:folder, project: project_permission.project) }
  let(:other_folder) { FactoryGirl.create(:folder) }

  it_behaves_like 'system_permission can access', :folder
  it_behaves_like 'system_permission can access', :other_folder

  it_behaves_like 'a user with project_permission', :create_file, allows: [:create?, :update?, :move?, :rename?], on: :folder
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :show?], denies: [:move?, :rename?], on: :folder
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:move?, :rename?], on: :folder

  it_behaves_like 'a user with project_permission', :create_file, allows: [], denies: [:move?, :rename?], on: :other_folder
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:move?, :rename?], on: :other_folder
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:move?, :rename?], on: :other_folder

  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file], denies: [:scope, :show?, :create?, :update?, :destroy?, :move?, :rename?], on: :folder
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file], denies: [:scope, :show?, :create?, :update?, :destroy?, :move?, :rename?], on: :other_folder

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(folder) }
      it { expect(resolved_scope).not_to include(other_folder) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, folder) }
      it { is_expected.not_to permit(user, other_folder) }
    end
  end
end
