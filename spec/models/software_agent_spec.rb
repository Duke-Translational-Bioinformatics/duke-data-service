require 'rails_helper'

RSpec.describe SoftwareAgent, type: :model do
  subject { FactoryBot.create(:software_agent) }
  let(:deleted_software_agent) { FactoryBot.create(:software_agent, :deleted) }

  it_behaves_like 'an audited model'

  it_behaves_like 'a kind' do
    let(:expected_kind) { 'dds-software-agent' }
    let(:kinded_class) { SoftwareAgent }
    let(:serialized_kind) { false }
  end
  it_behaves_like 'a graphed node' do
    let(:kind_name) { 'Agent' }
  end

  it_behaves_like 'a logically deleted model'

  describe 'associations' do
    it { should belong_to(:creator) }
    it { should have_one(:api_key) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:creator_id) }

    context 'when is_deleted' do
      subject { deleted_software_agent }

      it { should_not validate_presence_of(:name) }
      it { should_not validate_presence_of(:creator_id) }
    end
  end
end
