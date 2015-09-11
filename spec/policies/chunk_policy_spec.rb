require 'rails_helper'

describe ChunkPolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:upload) { FactoryGirl.create(:upload, project: project_permission.project) }
  let(:chunk) { FactoryGirl.create(:chunk, upload: upload) }
  let(:other_chunk) { FactoryGirl.create(:chunk) }

  let(:scope) { subject.new(user, chunk).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns chunks with project permissions' do
      expect(chunk).to be_persisted
      expect(other_chunk).to be_persisted
      expect(scope.all).to include(chunk)
      expect(scope.all).not_to include(other_chunk)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_chunk)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, chunk)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_chunk)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, chunk)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_chunk)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, chunk)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_chunk)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, chunk)
    end
  end
end
