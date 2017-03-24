require 'rails_helper'

RSpec.describe JobTracking do
  subject { Class.new { include JobTracking } }

  context '::transaction_key' do
    it {
      expect(subject).to respond_to(:transaction_key)
      expect(subject.transaction_key).to eq(subject.class.name)
    }
  end

  context '::initialize_job' do
    it {
      is_expected.to respond_to(:initialize_job).with(1).argument
    }

    context 'argument not transactionable' do
      let(:argument) { FactoryGirl.create(:user) }

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