require 'rails_helper'

RSpec.describe JobTransaction, type: :model do
  subject { FactoryBot.create(:job_transaction) }

  describe 'validations' do
    it {
      is_expected.to belong_to(:transactionable)
      is_expected.to validate_presence_of(:transactionable_id)
      is_expected.to validate_presence_of(:transactionable_type)
      is_expected.to validate_presence_of(:request_id)
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_presence_of(:state)
    }
  end

  describe '.oldest_completed_at' do
    let(:oldest_completed_at) { described_class.oldest_completed_at }
    it { expect(described_class).to respond_to(:oldest_completed_at) }
    it { expect(oldest_completed_at).to be_nil }

    context 'with multiple completed' do
      let(:complete_jobs) { FactoryBot.create_list(:job_transaction, 3, state: 'complete') }
      let(:complete_times) { complete_jobs.collect {|j| j.created_at} }
      before(:each) do
        expect(complete_jobs).to be_a Array
        complete_jobs.each {|j| expect(j.reload).to be_truthy}
      end
      it { expect(complete_times.uniq).to eq complete_times }
      it { expect(complete_times.sort).to eq complete_times }
      it { expect(oldest_completed_at).to eq complete_times.first }
    end
  end

  describe '.delete_all_complete_by_request_id' do
    let(:delete_all_complete_by_request_id) { described_class.delete_all_complete_by_request_id }
    it { expect(described_class).to respond_to(:delete_all_complete_by_request_id) }
    it { expect(delete_all_complete_by_request_id).to eq 0 }

    context 'with multiple completed' do
      let(:complete_jobs) { FactoryBot.create_list(:job_transaction, 3, state: 'complete') }
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_by_request_id}.to change{JobTransaction.count}.by(-3) }
    end

    context 'with multiple completed and referencing request ids' do
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3) }
      let(:complete_jobs) do
        initial_jobs.collect do |i|
          FactoryBot.create(:job_transaction, state: 'complete', request_id: i.request_id)
        end
      end
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_by_request_id}.to change{JobTransaction.count}.by(-6) }
    end
  end
end
