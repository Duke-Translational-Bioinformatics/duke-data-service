require 'rails_helper'

describe 'job_transaction:clean_up' do
  include_context "rake"

  let(:oldest_completed_at) { nil }
  before(:each) do
    expect(JobTransaction).to receive(:oldest_completed_at).and_return(oldest_completed_at)
  end

  context 'when oldest_completed_at returns nil' do
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_complete_by_request_id) }
    it { invoke_task(expected_stdout: /No completed JobTransactions found./) }
  end

  context 'when oldest completed from this month' do
    let(:oldest_completed_at) { Time.now - 1.day }
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_complete_by_request_id) }
    it { invoke_task(expected_stdout: /No completed transactions older than 1 month found./) }
  end

  context 'when oldest completed from 4 months ago' do
    let(:oldest_completed_at) { Time.now - 4.month - 1.day }
    before(:each) do
      expect(JobTransaction).to receive(:delete_all_complete_by_request_id).exactly(4).times
    end
    it { invoke_task(expected_stdout: /Delete from 4 months ago./) }
    it { invoke_task(expected_stdout: /Delete from 3 months ago./) }
    it { invoke_task(expected_stdout: /Delete from 2 months ago./) }
    it { invoke_task(expected_stdout: /Delete from 1 month ago./) }
  end
end