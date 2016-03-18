require 'rails_helper'

describe DataFilePolicy do
  include_context 'policy declarations'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:upload) { FactoryGirl.create(:upload, :completed, creator: user, project: project_permission.project) }
  let(:data_file) { FactoryGirl.create(:data_file, project: project_permission.project, upload: upload) }
  let(:data_file_without_upload) { FactoryGirl.create(:data_file, project: project_permission.project) }
  let(:other_data_file) { FactoryGirl.create(:data_file) }

  it_behaves_like 'system_permission can access', :data_file
  it_behaves_like 'system_permission can access', :data_file_without_upload
  it_behaves_like 'system_permission can access', :other_data_file

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(data_file) }
      it { expect(resolved_scope).to include(data_file_without_upload) }
      it { expect(resolved_scope).not_to include(other_data_file) }
    end
    permissions :show?, :destroy? do
      it { is_expected.to permit(user, data_file) }
      it { is_expected.to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
    end
    permissions :create?, :update? do
      it { is_expected.to permit(user, data_file) }
      it { is_expected.not_to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(data_file) }
      it { expect(resolved_scope).not_to include(data_file_without_upload) }
      it { expect(resolved_scope).not_to include(other_data_file) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, data_file) }
      it { is_expected.not_to permit(user, data_file_without_upload) }
      it { is_expected.not_to permit(user, other_data_file) }
    end
  end
end
