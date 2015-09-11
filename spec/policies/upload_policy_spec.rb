require 'rails_helper'

describe UploadPolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:upload) { FactoryGirl.build(:upload, project: project_permission.project) }
  let(:other_upload) { FactoryGirl.create(:upload) }

  let(:scope) { subject.new(user, upload).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns uploads with project permissions' do
      expect(upload.save).to be_truthy
      expect(other_upload).to be_persisted
      expect(scope.all).to include(upload)
      expect(scope.all).not_to include(other_upload)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_upload)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, upload)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_upload)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, upload)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_upload)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, upload)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_upload)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, upload)
    end
  end
end
