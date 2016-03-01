require 'rails_helper'

describe ChunkPolicy do
  include_context 'policy declarations'

  let(:project_permission) { FactoryGirl.create(:project_permission) }
  let(:user) { project_permission.user }
  let(:upload) { FactoryGirl.create(:upload, project: project_permission.project) }
  let(:chunk) { FactoryGirl.create(:chunk, upload: upload) }
  let(:other_chunk) { FactoryGirl.create(:chunk) }

  let(:scope) { subject.new(user, chunk).scope }

  context 'when user has project_permission' do
    let(:user) { project_permission.user }

    describe '.scope' do
      it { expect(resolved_scope).to include(chunk) }
      it { expect(resolved_scope).not_to include(other_chunk) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, chunk) }
      it { is_expected.not_to permit(user, other_chunk) }
    end
  end

  context 'when user does not have project_permission' do
    let(:user) { FactoryGirl.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).not_to include(chunk) }
      it { expect(resolved_scope).not_to include(other_chunk) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, chunk) }
      it { is_expected.not_to permit(user, other_chunk) }
    end
  end
end
