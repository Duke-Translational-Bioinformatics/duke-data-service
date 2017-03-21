require 'rails_helper'

RSpec.describe JobTracking do
  subject { Class.new { include JobTracking } }

  context '::initialize_job' do
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
          job_transaction = subject.initialize_job(argument)
        }.not_to raise_error
        expect(job_transaction).to be
        expect(job_transaction).to be_persisted
        expect(job_transaction.key).to eq(subject.transaction_key)
        expect(job_transaction.state).to eq('initialized')
      }
    end
  end

  describe '::start_job' do
    let(:transaction) { FactoryGirl.create(:job_transaction) }
    it { is_expected.to respond_to(:start_job).with(1).argument }
    it {
      subject.start_job(transaction)
      transaction.reload
      expect(transaction.state).to eq('in progress')
    }
  end

  describe '::complete_job' do
    let(:transaction) { FactoryGirl.create(:job_transaction) }
    it { is_expected.to respond_to(:complete_job).with(1).argument }
    it {
      subject.complete_job(transaction)
      transaction.reload
      expect(transaction.state).to eq('complete')
    }
  end
end
