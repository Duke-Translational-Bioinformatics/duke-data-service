require 'rails_helper'

RSpec.describe JobTracking do
  subject { Class.new { include JobTracking } }

  context '::transaction_key' do
    it {
      expect(subject).to respond_to(:transaction_key)
      expect(subject.transaction_key).to eq(subject.class.name)
    }
  end

  context '::register_job_status' do
    let(:transaction) { FactoryGirl.create(:job_transaction) }
    let(:expected_state) { 'testing' }
    before do
      expect(transaction).to be_persisted
      expect(transaction.transactionable).to be_persisted
    end

    it {
      is_expected.to respond_to(:register_job_status).with(3).arguments
    }

    context 'without key' do
      it {
        job_transaction = nil
        expect {
          expect {
            job_transaction = subject.register_job_status(
              transaction,
              expected_state
            )
          }.not_to raise_error
        }.to change{JobTransaction.count}.by(1)
        expect(job_transaction).to be
        expect(job_transaction).to be_persisted
        expect(job_transaction.transactionable_id).to eq(transaction.transactionable_id)
        expect(job_transaction.key).to eq(transaction.key)
        expect(job_transaction.request_id).to eq(transaction.request_id)
        expect(job_transaction.state).to eq(expected_state)
      }
    end

    context 'with key' do
      let(:expected_key) { 'TestKey' }

      it {
        job_transaction = nil
        expect {
          expect {
            job_transaction = subject.register_job_status(
              transaction,
              expected_state,
              expected_key
            )
          }.not_to raise_error
        }.to change{JobTransaction.count}.by(1)
        expect(job_transaction).to be
        expect(job_transaction).to be_persisted
        expect(job_transaction.transactionable_id).to eq(transaction.transactionable_id)
        expect(job_transaction.key).to eq(expected_key)
        expect(job_transaction.request_id).to eq(transaction.request_id)
        expect(job_transaction.state).to eq(expected_state)
      }
    end
  end

  context '::initialize_job' do
    it {
      is_expected.to respond_to(:initialize_job).with(1).argument
    }

    context 'argument not transactionable' do
      let(:argument) { Object.new }

      it {
        expect(argument.class).not_to include(JobTransactionable)
        expect {
          subject.initialize_job(argument)
        }.to raise_error(ArgumentError)
      }
    end

    context 'argument transactionable' do
      let(:argument) { FactoryGirl.create(:folder) }

      it {
        expect(argument.class).to include(JobTransactionable)
        job_transaction = nil
        expect {
          expect {
            job_transaction = subject.initialize_job(argument)
          }.not_to raise_error
        }.to change{JobTransaction.count}.by(1)
        expect(job_transaction).to be
        expect(job_transaction).to be_persisted
        expect(job_transaction.key).to eq(subject.transaction_key)
        expect(job_transaction.state).to eq('initialized')
      }
    end
  end

  describe '::start_job' do
    let(:initial_transaction) { FactoryGirl.create(:job_transaction, state: 'initialized') }
    it { is_expected.to respond_to(:start_job).with(1).argument }
    it {
      expect {
        subject.start_job(initial_transaction)
      }.to change{
          initial_transaction.transactionable.job_transactions.where(
            key: initial_transaction.key,
            request_id: initial_transaction.request_id,
            state: 'in progress'
          ).count
      }.by(1)
    }
  end

  describe '::complete_job' do
    let(:initial_transaction) { FactoryGirl.create(:job_transaction) }
    it { is_expected.to respond_to(:complete_job).with(1).argument }
    it {
      expect {
        subject.complete_job(initial_transaction)
      }.to change{
          initial_transaction.transactionable.job_transactions.where(
            key: initial_transaction.key,
            request_id: initial_transaction.request_id,
            state: 'complete'
          ).count
      }.by(1)
    }
  end
end
