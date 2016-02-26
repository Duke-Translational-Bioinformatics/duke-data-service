require 'rails_helper'

describe AffiliationPolicy do
  subject { described_class }
  let(:record_class) { 
    described_class.name.gsub(/Policy$/,'').constantize 
  }
  let(:resolved_scope) {
    described_class::Scope.new(user, record_class.all).resolve
  }

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:affiliation) { FactoryGirl.create(:affiliation, project: project_permission.project) }
  let(:other_affiliation) { FactoryGirl.create(:affiliation) }

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(affiliation) }
      it { expect(resolved_scope).not_to include(other_affiliation) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, affiliation) }
      it { is_expected.not_to permit(user, other_affiliation) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(affiliation) }
      it { expect(resolved_scope).not_to include(other_affiliation) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, affiliation) }
      it { is_expected.not_to permit(user, other_affiliation) }
    end
  end

  context 'when user has system_permission' do
    let(:user) { FactoryGirl.create(:system_permission).user }

    describe '.scope' do
      it { expect(resolved_scope).to include(affiliation) }
      it { expect(resolved_scope).to include(other_affiliation) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, affiliation) }
      it { is_expected.to permit(user, other_affiliation) }
    end
  end
end
