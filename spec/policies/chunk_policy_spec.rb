require 'rails_helper'

describe ChunkPolicy do
  include_context 'policy declarations'

  let(:auth_role) { FactoryGirl.create(:auth_role) }
  let(:project_permission) { FactoryGirl.create(:project_permission, auth_role: auth_role) }
  let(:upload) { FactoryGirl.create(:upload, project: project_permission.project) }
  let(:chunk) { FactoryGirl.create(:chunk, upload: upload) }
  let(:other_chunk) { FactoryGirl.create(:chunk) }

  it_behaves_like 'system_permission can access', :chunk
  it_behaves_like 'system_permission can access', :other_chunk

  it_behaves_like 'a user with project_permission', :create_file, allows: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :chunk
  it_behaves_like 'a user with project_permission', :create_file, allows: [], on: :other_chunk

  it_behaves_like 'a user without project_permission', :create_file, denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :chunk
  it_behaves_like 'a user without project_permission', :create_file, denies: [:scope, :index?, :show?, :create?, :update?, :destroy?], on: :other_chunk

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(chunk) }
      it { expect(resolved_scope).not_to include(other_chunk) }
    end
    permissions :index?, :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, chunk) }
      it { is_expected.not_to permit(user, other_chunk) }
    end
  end
end
