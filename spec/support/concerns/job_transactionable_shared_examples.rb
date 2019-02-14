shared_examples 'a job_transactionable model' do
  it {
    expect(described_class).to include(JobTransactionable)
    is_expected.to respond_to(:current_transaction)
    is_expected.to have_many(:job_transactions)

    is_expected.to respond_to(:root_create_transaction)
    is_expected.to respond_to(:root_update_transaction)
    is_expected.to callback(:root_create_transaction)
      .before(:create)
    is_expected.to callback(:root_update_transaction)
      .before(:update)
    is_expected.to callback(:root_destroy_transaction)
      .before(:destroy)
    is_expected.to callback(:root_update_transaction)
      .after(:touch)
  }

  describe '#create_transaction' do
    let(:transaction_state) {'testing'}

    context 'with nil current_transaction' do
      let(:audit_current_request_uuid) { ApplicationAudit.generate_current_request_uuid }
      it {
        subject.current_transaction = nil
        expect(subject.current_transaction).to be_nil
        subject.create_transaction(transaction_state)
        expect(subject.current_transaction).not_to be_nil
        expect(subject.current_transaction).not_to be_persisted
        expect(subject.current_transaction.state).to eq(transaction_state)
        expect(audit_current_request_uuid).not_to be_nil
        expect(subject.current_transaction.request_id).to eq(audit_current_request_uuid)
      }
    end

    context 'with preset current_transaction' do
      let(:existing_current_transaction)  {
        subject.create_transaction 'pretest'
      }

      it {
        expect(existing_current_transaction).not_to be_nil
        expect(subject.current_transaction).not_to be_nil
        expect(subject.current_transaction.id).to eq(existing_current_transaction.id)
        subject.create_transaction(transaction_state)
        expect(subject.current_transaction).not_to be_nil
        expect(subject.current_transaction).not_to be_persisted
        expect(subject.current_transaction.state).to eq(transaction_state)
        expect(subject.current_transaction.request_id).to eq(existing_current_transaction.request_id)
      }
    end

    it { expect(subject.save).to be_truthy }
    it { expect{subject.save}.to change{JobTransaction.count} }
  end

  describe '#root_create_transaction' do
    before do
      expect(subject).to receive(:create_transaction).with('created').and_call_original
    end
    it { expect(subject.root_create_transaction).to be_a JobTransaction }
  end

  describe '#root_update_transaction' do
    before do
      expect(subject).to receive(:create_transaction).with('updated').and_call_original
    end
    it { expect(subject.root_update_transaction).to be_a JobTransaction }
  end

  describe '#root_destroy_transaction' do
    before do
      expect(subject).to receive(:create_transaction).with('destroyed').and_call_original
    end
    it { expect(subject.root_destroy_transaction).to be_a JobTransaction }
    it { expect(subject.root_destroy_transaction).to be_persisted }
  end

  describe '#touch' do
    before do
      expect(subject).to receive(:root_update_transaction)
    end
    it { expect{subject.touch}.not_to raise_error }
  end
end
