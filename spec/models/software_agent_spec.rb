require 'rails_helper'

RSpec.describe SoftwareAgent, type: :model do
  subject { FactoryGirl.create(:software_agent) }
  let(:deleted_software_agent) { FactoryGirl.create(:software_agent, :deleted) }

  it_behaves_like 'an audited model'

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
