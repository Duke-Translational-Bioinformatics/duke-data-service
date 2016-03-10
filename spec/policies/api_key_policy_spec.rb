require 'rails_helper'

describe ApiKeyPolicy do
  include_context 'policy declarations'
  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:user_key) { FactoryGirl.create(:api_key, user_id: user.id) }
  let(:other_user_key) { FactoryGirl.create(:api_key, user_id: other_user.id) }
  let(:user_software_agent) { FactoryGirl.create(:software_agent, :with_key, creator: user)}
  let(:other_user_software_agent) { FactoryGirl.create(:software_agent, :with_key, creator: other_user)}
  let(:user_software_agent_key) { FactoryGirl.create(:api_key, software_agent_id: user_software_agent.id) }
  let(:other_user_software_agent_key) { FactoryGirl.create(:api_key, software_agent_id: other_user_software_agent.id) }

  it_behaves_like 'system_permission can access', :user_key
  it_behaves_like 'system_permission cannot access', :user_key, 'with software_agent'
  it_behaves_like 'system_permission can access', :other_user_key
  it_behaves_like 'system_permission cannot access', :other_user_key, 'with software_agent'
  it_behaves_like 'system_permission can access', :user_software_agent_key
  it_behaves_like 'system_permission can access', :other_user_software_agent_key
  it_behaves_like 'system_permission cannot access', :user_software_agent_key, 'with software_agent'
  it_behaves_like 'system_permission cannot access', :other_user_software_agent_key, 'with software_agent'

  context 'user_key' do
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, user_key) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, other_user_key) }
    end
    it_behaves_like 'software_agent cannot access', :user_key
    it_behaves_like 'software_agent cannot access', :other_user_key
  end

  context 'software_agent_key' do
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.to permit(user, user_software_agent_key) }
    end
    permissions :show?, :create?, :update?, :destroy? do
      it { is_expected.not_to permit(user, other_user_software_agent_key) }
    end
    it_behaves_like 'software_agent cannot access', :user_software_agent_key
    it_behaves_like 'software_agent cannot access', :other_user_software_agent_key
  end
end
