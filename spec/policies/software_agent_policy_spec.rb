require 'rails_helper'

describe SoftwareAgentPolicy do

  let(:user) { FactoryGirl.create(:user) }
  let!(:software_agent) { FactoryGirl.create(:software_agent) }
  let(:creator) { software_agent.creator }
  let(:system_admin) { system_permission.user }
  let(:system_permission) { FactoryGirl.create(:system_permission) }

  let(:user_scope) { subject.new(user, software_agent).scope }
  let(:system_admin_scope) { subject.new(system_admin, software_agent).scope }
  let(:creator_scope) { subject.new(creator, software_agent).scope }

  subject { described_class }

  permissions ".scope" do
    it {expect(user_scope.all).to include(software_agent)}
    it {expect(system_admin_scope.all).to include(software_agent)}
    it {expect(creator_scope.all).to include(software_agent)}
  end

  permissions :show? do
    it {is_expected.to permit(user, software_agent)}
    it {is_expected.to permit(creator, software_agent)}
    it {is_expected.to permit(system_admin, software_agent)}
  end

  permissions :create? do
    it {is_expected.to permit(user, software_agent)}
    it {is_expected.to permit(creator, software_agent)}
    it {is_expected.to permit(system_admin, software_agent)}
  end

  permissions :update? do
    it {is_expected.not_to permit(user, software_agent)}
    it {is_expected.to permit(creator, software_agent)}
    it {is_expected.to permit(system_admin, software_agent)}
  end

  permissions :destroy? do
    it {is_expected.not_to permit(user, software_agent)}
    it {is_expected.to permit(creator, software_agent)}
    it {is_expected.to permit(system_admin, software_agent)}
  end
end
