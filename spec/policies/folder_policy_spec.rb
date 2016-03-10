require 'rails_helper'

describe FolderPolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:folder) { FactoryGirl.build(:folder, project: project_permission.project) }
  let(:other_folder) { FactoryGirl.create(:folder) }

  let(:scope) { subject.new(user, folder).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns folders with project permissions' do
      expect(folder.save).to be_truthy
      expect(other_folder).to be_persisted
      expect(scope.all).to include(folder)
      expect(scope.all).not_to include(other_folder)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_folder)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, folder)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_folder)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, folder)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_folder)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, folder)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_folder)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, folder)
    end
  end
end
