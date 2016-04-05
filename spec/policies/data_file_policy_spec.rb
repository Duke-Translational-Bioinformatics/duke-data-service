require 'rails_helper'

describe DataFilePolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:upload) { FactoryGirl.create(:upload, :completed, creator: user, project: project_permission.project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project, upload: upload) }
  let(:data_file_without_upload) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:other_data_file) { FactoryGirl.create(:data_file) }

  it_behaves_like 'system_permission can access', :data_file
  it_behaves_like 'system_permission can access', :data_file_without_upload
  it_behaves_like 'system_permission can access', :other_data_file

  it_behaves_like 'a user with project_permission', :create_file, allows: [:create?, :move?, :rename?], denies: [:download?], on: :data_file
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?], denies: [:download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], denies: [:move?, :rename?], on: :data_file

  it_behaves_like 'a user with project_permission', :create_file, allows: [:move?, :rename?], denies: [:download?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :delete_file, allows: [:destroy?], denies: [:download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user with project_permission', :download_file, allows: [:download?], denies: [:move?, :rename?], on: :data_file_without_upload

  it_behaves_like 'a user with project_permission', :create_file, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :delete_file, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file
  it_behaves_like 'a user with project_permission', :download_file, allows: [], denies: [:download?, :move?, :rename?], on: :other_data_file

  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :data_file
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :data_file_without_upload
  it_behaves_like 'a user without project_permission', [:create_file, :view_project, :update_file, :delete_file, :download_file], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :download?, :move?, :rename?], on: :other_data_file

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(data_file) }
      it { expect(resolved_scope).not_to include(data_file_without_upload) }
      it { expect(resolved_scope).not_to include(other_data_file) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, data_file) }
      it { is_expected.not_to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
    end
  end
end
