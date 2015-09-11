require 'rails_helper'

describe DataFilePolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:data_file) { FactoryGirl.build(:data_file, project: project_permission.project) }
  let(:other_data_file) { FactoryGirl.create(:data_file) }

  let(:scope) { subject.new(user, data_file).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns data_files with project permissions' do
      expect(data_file.save).to be_truthy
      expect(other_data_file).to be_persisted
      expect(scope.all).to include(data_file)
      expect(scope.all).not_to include(other_data_file)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_data_file)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, data_file)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_data_file)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, data_file)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_data_file)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, data_file)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_data_file)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, data_file)
    end
  end
end
