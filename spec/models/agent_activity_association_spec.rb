require 'rails_helper'

RSpec.describe AgentActivityAssociation, type: :model do
  context 'user activity association' do
    subject { associated_with_relation }
    let(:associated_with_relation) { FactoryGirl.create(:user_activity_association) }

    it_behaves_like 'an audited model'
    it_behaves_like 'a graphed relation', auto_create: true do
      let(:from_model) { associated_with_relation.agent }
      let(:to_model) { associated_with_relation.activity }
      let(:rel_type) { 'WasAssociatedWith' }
    end
    describe 'validations' do
      it { is_expected.to validate_presence_of :agent }
      it { is_expected.to validate_presence_of :activity }
    end
  end

  context 'software_agent activity association' do
    subject { associated_with_relation }
    let(:associated_with_relation) { FactoryGirl.create(:software_agent_activity_association) }

    it_behaves_like 'an audited model'
    it_behaves_like 'a graphed relation', auto_create: true do
      let(:from_model) { associated_with_relation.agent }
      let(:to_model) { associated_with_relation.activity }
      let(:rel_type) { 'WasAssociatedWith' }
    end
  end
end
