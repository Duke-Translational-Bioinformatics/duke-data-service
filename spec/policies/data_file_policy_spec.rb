require 'rails_helper'

describe DataFilePolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, creator: user, project: project_permission.project) }
  let(:data_file) { FactoryBot.create(:data_file, project: project_permission.project, upload: upload) }
  let(:data_file_without_upload) { FactoryBot.create(:data_file, project: project_permission.project) }
  let(:other_data_file) { FactoryBot.create(:data_file) }

  it_behaves_like 'system_permission can access', :data_file
  it_behaves_like 'system_permission can access', :data_file_without_upload
  it_behaves_like 'system_permission can access', :other_data_file

  it_behaves_like 'a user with project_permission', :create_file, allows: [:create?, :move?, :restore?], denies: [:download?, :rename?], on: :data_file
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?, :restore?], on: :data_file
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?, :rename?], denies: [:download?, :move?, :restore?], on: :data_file
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?, :move?, :rename?, :restore?], on: :data_file
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], denies: [:move?, :rename?, :restore?], on: :data_file

  context 'when user is not upload creator' do
    let(:upload) { FactoryBot.create(:upload, :completed, :with_fingerprint, project: project_permission.project) }

    it_behaves_like 'a user with project_permission', :create_file, allows: [:move?, :restore?], denies: [:download?, :rename?], on: :data_file
    it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?, :restore?], on: :data_file
    it_behaves_like 'a user with project_permission', :update_file, allows: [:update?, :rename?], denies: [:download?, :move?, :restore?], on: :data_file
    it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?, :move?, :rename?, :restore?], on: :data_file
    it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], denies: [:move?, :rename?, :restore?], on: :data_file
  end

  it_behaves_like 'a user with project_permission', :create_file, allows: [:move?, :restore?], denies: [:download?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :restore?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?, :rename?], denies: [:download?, :move?, :restore?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?, :move?, :restore?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], denies: [:move?, :restore?, :rename?], on: :data_file_without_upload

  it_behaves_like 'a user with project_permission', :create_file, allows: [], denies: [:download?, :move?, :restore?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:download?, :move?, :restore?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:download?, :move?, :restore?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:download?, :move?, :restore?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :download_file, allows: [], denies: [:download?, :move?, :restore?, :rename?], on: :other_data_file

  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :restore?, :rename?], on: :data_file
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :restore?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :restore?, :rename?], on: :other_data_file

  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(data_file) }
      it { expect(resolved_scope).not_to include(data_file_without_upload) }
      it { expect(resolved_scope).not_to include(other_data_file) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy?, :move?, :restore?, :rename? do
      it { is_expected.not_to permit(user, data_file) }
      it { is_expected.not_to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
    end
  end
end
