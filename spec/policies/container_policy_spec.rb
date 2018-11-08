require 'rails_helper'

describe ContainerPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, creator: user, project: project_permission.project, storage_provider: mocked_storage_provider) }
  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project, upload: upload) }
  let(:data_file_without_upload) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:other_data_file) { FactoryBot.create(:data_file) }
  let(:folder) { FactoryBot.create(:folder, project: project_permission.project) }
  let(:other_folder) { FactoryBot.create(:folder) }

  it_behaves_like 'system_permission can access', :data_file, allows: [:scope, :index?, :show?]
  it_behaves_like 'system_permission can access', :data_file_without_upload, allows: [:scope, :index?, :show?]
  it_behaves_like 'system_permission can access', :other_data_file, allows: [:scope, :index?, :show?]
  it_behaves_like 'system_permission can access', :folder, allows: [:scope, :index?, :show?]
  it_behaves_like 'system_permission can access', :other_folder, allows: [:scope, :index?, :show?]

  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:move?, :rename?], on: :folder
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file

  it_behaves_like 'a user with project_permission', :create_file, allows: [], denies: [:move?, :rename?], on: :other_folder
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:move?, :rename?], on: :other_folder
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:move?, :rename?], on: :other_folder

  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :other_data_file
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :move?, :rename?], on: :folder
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :move?, :rename?], on: :other_folder

  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(data_file) }
      it { expect(resolved_scope).not_to include(data_file_without_upload) }
      it { expect(resolved_scope).not_to include(other_data_file) }
      it { expect(resolved_scope).not_to include(folder) }
      it { expect(resolved_scope).not_to include(other_folder) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, data_file) }
      it { is_expected.not_to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
      it { is_expected.not_to permit(user, folder) }
      it { is_expected.not_to permit(user, other_folder) }
    end
  end
end
