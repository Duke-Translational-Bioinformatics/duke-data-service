require 'rails_helper'

RSpec.describe ApplicationAudit, type: :model do
  it { expect(Audited.audit_class).to eq described_class }
  let(:original_store_keys) { Audited.store.keys }
  before(:each) { expect { original_store_keys }.not_to raise_error }
  after(:each) do
    described_class.reset_store
    expect(Audited.store.keys).to eq original_store_keys
  end

  it { expect{subject.save}.not_to raise_error }

  it { expect(described_class).to respond_to(:reset_store) }

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
        it { expect(subject.comment).to be_a Hash }
        it { expect(subject.comment).not_to include('software_agent_id') }
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

  describe '.store_current_request_uuid' do
    it { expect(described_class).to respond_to(:store_current_request_uuid).with(1).argument }
    it { expect(subject.request_uuid).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.store_current_request_uuid(request_uuid) }.not_to raise_error
      end
      let(:request_uuid) { SecureRandom.uuid }
      it { expect(subject.request_uuid).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.request_uuid).to eq request_uuid }
      end
    end
  end

  describe '.store_current_remote_address' do
    it { expect(described_class).to respond_to(:store_current_remote_address).with(1).argument }
    it { expect(subject.remote_address).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.store_current_remote_address(remote_address) }.not_to raise_error
      end
      let(:remote_address) { Faker::Internet.ip_v4_address }
      it { expect(subject.remote_address).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.remote_address).to eq remote_address }
      end
    end
  end
end
