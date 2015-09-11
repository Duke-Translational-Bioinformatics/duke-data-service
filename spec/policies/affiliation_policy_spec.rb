require 'rails_helper'

describe AffiliationPolicy do
  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:affiliation) { FactoryGirl.create(:affiliation, project: project_permission.project) }
  let(:other_affiliation) { FactoryGirl.create(:affiliation) }

  let(:scope) { subject.new(user, affiliation).scope }

  subject { described_class }

  permissions ".scope" do
    it 'returns affiliations with project permissions' do
      expect(affiliation).to be_persisted
      expect(other_affiliation).to be_persisted
      expect(scope.all).to include(affiliation)
      expect(scope.all).not_to include(other_affiliation)
    end
  end

  permissions :show? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_affiliation)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, affiliation)
    end
  end

  permissions :create? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_affiliation)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, affiliation)
    end
  end

  permissions :update? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_affiliation)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, affiliation)
    end
  end

  permissions :destroy? do
    it 'denies access without project permission' do
      is_expected.not_to permit(user, other_affiliation)
    end

    it 'grants access with project permission' do
      is_expected.to permit(user, affiliation)
    end
  end
end
