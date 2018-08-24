require 'rails_helper'

RSpec.describe ApplicationAudit, type: :model do
  it { expect(described_class).to respond_to(:clear_store) }
  it { expect(Audited.audit_class).to eq described_class }
  let(:store_keys) { [:audited_user, :current_request_uuid, :current_remote_address] }
  after(:each) do
    described_class.clear_store
    expect(Audited.store.keys).not_to include *store_keys
  end

  it { expect{subject.save}.not_to raise_error }

  describe '.current_user=' do
    it { expect(described_class).to respond_to(:current_user=).with(1).argument }
    it { expect(subject.user).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.current_user = current_user }.not_to raise_error
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
        expect{ described_class.current_user = current_user }.not_to raise_error
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

  describe '.current_user' do
    it { expect(described_class).to respond_to(:current_user) }
    it { expect(described_class.current_user).to be_nil }

    context 'after .current_user= called' do
      before(:each) do
        expect{ described_class.current_user = current_user }.not_to raise_error
      end
      let(:current_user) { FactoryBot.create(:user, :save_without_auditing) }
      it { expect(described_class.current_user).to eq current_user }
    end
  end

  describe '.current_request_uuid=' do
    it { expect(described_class).to respond_to(:current_request_uuid=).with(1).argument }
    it { expect(subject.request_uuid).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.current_request_uuid = request_uuid }.not_to raise_error
      end
      let(:request_uuid) { SecureRandom.uuid }
      it { expect(subject.request_uuid).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.request_uuid).to eq request_uuid }
      end
    end
  end

  describe '.current_remote_address=' do
    it { expect(described_class).to respond_to(:current_remote_address=).with(1).argument }
    it { expect(subject.remote_address).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.current_remote_address = remote_address }.not_to raise_error
      end
      let(:remote_address) { Faker::Internet.ip_v4_address }
      it { expect(subject.remote_address).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.remote_address).to eq remote_address }
      end
    end
  end

  describe '.current_comment=' do
    it { expect(described_class).to respond_to(:current_comment=).with(1).argument }
    it { expect(subject.comment).to be_nil }

    context 'when called' do
      before(:each) do
        expect{ described_class.current_comment = comment }.not_to raise_error
      end
      let(:comment) { {
        endpoint: Faker::Internet.url,
        action: 'GET'
      } }
      let(:expected_comment) { comment.stringify_keys }
      it { expect(subject.comment).to be_nil }

      context 'after subject#save' do
        before(:each) { expect(subject.save).to be_truthy }
        it { expect(subject.comment).not_to eq comment }
        it { expect(subject.comment).to eq expected_comment }
      end

      context 'with subject.comment set' do
        before(:each) { subject.comment = subject_comment }
        let(:subject_comment) { {'foo' => 'bar'} }
        let(:expected_comment) { subject_comment.merge(comment).stringify_keys }
        it { expect(subject.comment).to eq subject_comment }

        context 'after subject#save' do
          before(:each) { expect(subject.save).to be_truthy }
          it { expect(subject.comment).to eq expected_comment }
        end
      end
    end
  end
end
