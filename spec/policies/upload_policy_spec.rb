require 'rails_helper'

describe UploadPolicy do
  include_context 'policy declarations'
  include_context 'mock all Uploads StorageProvider'

  let(:auth_role) { FactoryBot.create(:auth_role) }
  let(:project_permission) { FactoryBot.create(:project_permission, auth_role: auth_role) }
  let(:upload) { FactoryBot.create(:upload, project: project_permission.project) }
  let(:other_upload) { FactoryBot.create(:upload) }

  it_behaves_like 'system_permission can access', :upload
  it_behaves_like 'system_permission can access', :other_upload

  it_behaves_like 'a user with project_permission', :create_file, allows: [:create?, :complete?], on: :upload
  it_behaves_like 'a user with project_permission', :update_file, allows: [:update?], on: :upload
  it_behaves_like 'a user with project_permission', :view_project, allows: [:scope, :index?, :show?], denies: [:complete?], on: :upload

  it_behaves_like 'a user with project_permission', :create_file, allows: [], denies: [:complete?], on: :other_upload
  it_behaves_like 'a user with project_permission', :update_file, allows: [], denies: [:complete?], on: :other_upload
  it_behaves_like 'a user with project_permission', :view_project, allows: [], denies: [:complete?], on: :other_upload

  it_behaves_like 'a user without project_permission', [:create_file, :update_file, :view_project], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :complete?], on: :upload
  it_behaves_like 'a user without project_permission', [:create_file, :update_file, :view_project], denies: [:scope, :index?, :show?, :create?, :update?, :destroy?, :complete?], on: :other_upload


  context 'when user does not have project_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(upload) }
      it { expect(resolved_scope).not_to include(other_upload) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, upload) }
      it { is_expected.not_to permit(user, other_upload) }
    end
  end
end
