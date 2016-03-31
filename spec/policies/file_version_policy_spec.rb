require 'rails_helper'

describe FileVersionPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:file_version) { FactoryGirl.create(:file_version, data_file: data_file) }
  let(:other_file_version) { FactoryGirl.create(:file_version) }

  it_behaves_like 'system_permission can access', :file_version
  it_behaves_like 'system_permission can access', :other_file_version

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :show?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?, :create?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], on: :file_version

  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :download_file, allows: [], denies: [:download?], on: :other_file_version

  it_behaves_like 'a user without project_permission', [:view_project, :update_file, :delete_file, :download_file], denies: [:scope, :show?, :create?, :update?, :destroy?, :download?], on: :file_version
  it_behaves_like 'a user without project_permission', [:view_project, :update_file, :delete_file, :download_file], denies: [:scope, :show?, :create?, :update?, :destroy?, :download?], on: :other_file_version

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(file_version) }
      it { expect(resolved_scope).not_to include(other_file_version) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, file_version) }
      it { is_expected.not_to permit(user, other_file_version) }
    end
  end
end
