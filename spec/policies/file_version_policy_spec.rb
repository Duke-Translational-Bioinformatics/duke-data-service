require 'rails_helper'

describe FileVersionPolicy do
  include_context 'policy declarations'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:file_version) { FactoryGirl.create(:file_version, data_file: data_file) }
  let(:other_file_version) { FactoryGirl.create(:file_version) }

  it_behaves_like 'system_permission can access', :file_version
  it_behaves_like 'system_permission can access', :other_file_version

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(file_version) }
      it { expect(resolved_scope).not_to include(other_file_version) }
    end
    permissions :show?, :destroy?, :create?, :update? do
      it { is_expected.to permit(user, file_version) }
      it { is_expected.not_to permit(user, other_file_version) }
    end
  end

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
