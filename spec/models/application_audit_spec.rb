require 'rails_helper'

RSpec.describe ApplicationAudit, type: :model do
  it { expect(Audited.audit_class).to eq described_class }
  let(:original_store_keys) { Audited.store.keys }
  before(:each) { expect { original_store_keys }.not_to raise_error }
  after(:each) do
    Audited.store.keep_if {|k,v| original_store_keys.include? k}
    expect(Audited.store.keys).to eq original_store_keys
  end

  it { expect{subject.save}.not_to raise_error }

  describe '.store_current_user' do
    it { expect(described_class).to respond_to(:store_current_user).with(1).argument }
    it { expect(subject.user).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.store_current_user(current_user) }.not_to raise_error
      end
      let(:current_user) { FactoryBot.create(:user, :save_without_auditing) }
      it { expect(subject.user).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.user).to eq current_user }
      end
    end

    context 'when called with user.current_software_agent set' do
      before(:each) do
        expect{ described_class.store_current_user(current_user) }.not_to raise_error
      end
      let(:current_agent) { FactoryBot.create(:software_agent, :save_without_auditing) }
      let(:current_user) { FactoryBot.create(:user, :save_without_auditing, current_software_agent: current_agent) }
      it { expect(subject.user).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.user).to eq current_user }
        it { expect(subject.comment).to be_a Hash }
        it { expect(subject.comment).to include('software_agent_id' => current_agent.id) }
      end
    end
  end
end
