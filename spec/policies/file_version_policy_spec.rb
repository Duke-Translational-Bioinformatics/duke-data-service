require 'rails_helper'

describe FileVersionPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:file_version) { FactoryBot.create(:file_version, data_file: data_file) }
  let(:other_file_version) { FactoryBot.create(:file_version) }

  it_behaves_like 'system_permission can access', :file_version
  it_behaves_like 'system_permission can access', :other_file_version

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?, :create?, :restore?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?], on: :file_version
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], on: :file_version

  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:download?], on: :other_file_version
  it_behaves_like 'a user with project_permission', :download_file, allows: [], denies: [:download?], on: :other_file_version

  it_behaves_like 'a user without project_permission', [:view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :restore?, :update?, :destroy?, :download?], on: :file_version
  it_behaves_like 'a user without project_permission', [:view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :restore?, :update?, :destroy?, :download?], on: :other_file_version

  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(file_version) }
      it { expect(resolved_scope).not_to include(other_file_version) }
    end
    permissions :index?, :show?, :create?, :restore?, :update?, :destroy? do
      it { is_expected.not_to permit(user, file_version) }
      it { is_expected.not_to permit(user, other_file_version) }
    end
  end
end
