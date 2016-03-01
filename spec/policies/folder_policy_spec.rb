require 'rails_helper'

describe FolderPolicy do
  include_context 'policy declarations'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:folder) { FactoryGirl.create(:folder, project: project_permission.project) }
  let(:other_folder) { FactoryGirl.create(:folder) }

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(folder) }
      it { expect(resolved_scope).not_to include(other_folder) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, folder) }
      it { is_expected.not_to permit(user, other_folder) }
    end
  end

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
