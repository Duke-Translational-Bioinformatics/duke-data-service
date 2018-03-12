require 'rails_helper'

describe SoftwareAgentPolicy do
  include_context 'policy declarations'

  let(:software_agent) { FactoryBot.create(:software_agent) }
  let(:other_software_agent) { FactoryBot.create(:software_agent) }

  it_behaves_like 'system_permission can access', :software_agent
  it_behaves_like 'system_permission can access', :other_software_agent
  it_behaves_like 'system_permission cannot access', :software_agent, 'with software_agent'

  context 'when user is creator of software_agent' do
    let(:user) { software_agent.creator }

    describe '.scope' do
      it { expect(resolved_scope).to include(software_agent) }
      it { expect(resolved_scope).to include(other_software_agent) }
    end
    permissions :index?, :show?, :create? do
      it { is_expected.to permit(user, software_agent) }
      it { is_expected.to permit(user, other_software_agent) }
    end
    permissions :update?, :destroy? do
      it { is_expected.to permit(user, software_agent) }
      it { is_expected.not_to permit(user, other_software_agent) }
    end

    it_behaves_like 'software_agent cannot access', :software_agent
    it_behaves_like 'software_agent cannot access', :other_software_agent
  end

  context 'when user does not have system_permission' do
    let(:user) { FactoryBot.create(:user) }

    describe '.scope' do
      it { expect(resolved_scope).to include(software_agent) }
      it { expect(resolved_scope).to include(other_software_agent) }
    end
    permissions :index?, :show?, :create? do
      it { is_expected.to permit(user, software_agent) }
      it { is_expected.to permit(user, other_software_agent) }
    end
    permissions :update?, :destroy? do
      it { is_expected.not_to permit(user, software_agent) }
      it { is_expected.not_to permit(user, other_software_agent) }
    end
    it_behaves_like 'software_agent cannot access', :software_agent
    it_behaves_like 'software_agent cannot access', :other_software_agent
  end
end
