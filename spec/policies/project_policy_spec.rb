require 'rails_helper'

describe ProjectPolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:project) { project_permission.project }
  let(:other_project) { FactoryGirl.create(:project) }
  
  let(:scope) { subject.new(user, project).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns projects with project permissions' do
      expect(project).to be_persisted
      expect(other_project).to be_persisted
      expect(scope.all).to include(project)
      expect(scope.all).not_to include(other_project)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project)
    end
  end

  permissions :create? do
    it 'grants access without project permission' do
      is_expected.to permit(user, other_project)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_project)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, project)
    end
  end
end
