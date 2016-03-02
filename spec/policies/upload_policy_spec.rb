require 'rails_helper'

describe UploadPolicy do
  include_context 'policy declarations'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:upload) { FactoryGirl.create(:upload, project: project_permission.project) }
  let(:other_upload) { FactoryGirl.create(:upload) }

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(upload) }
      it { expect(resolved_scope).not_to include(other_upload) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, upload) }
      it { is_expected.not_to permit(user, other_upload) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(upload) }
      it { expect(resolved_scope).not_to include(other_upload) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, upload) }
      it { is_expected.not_to permit(user, other_upload) }
    end
  end
end
