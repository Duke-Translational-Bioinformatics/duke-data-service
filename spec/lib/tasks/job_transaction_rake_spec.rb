require 'rails_helper'

describe 'job_transaction:clean_up:completed' do
  include ActiveSupport::Testing::TimeHelpers
  include_context "rake"

  let(:oldest_completed_at) { nil }
  around(:each) do |example|
    travel_to(Time.now) do #freeze_time
      example.run
    end
  end
  before(:each) do
    expect(JobTransaction).to receive(:oldest_completed_at).and_return(oldest_completed_at)
  end

  context 'when oldest_completed_at returns nil' do
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_complete_jobs) }
    it { invoke_task(expected_stdout: /No completed JobTransactions found./) }
  end

  context 'when oldest completed from this month' do
    let(:oldest_completed_at) { Time.now - 1.day }
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_complete_jobs) }
    it { invoke_task(expected_stdout: /No completed JobTransactions older than 1 month found./) }
  end

  context 'when oldest completed from 4 months ago' do
    let(:oldest_completed_at) { Time.now - 4.month - 2.day }
    let(:deleted_counts) { Array.new(4) { Faker::Number.between(0, 1000) } }
    before(:each) do
      4.times do |i|
        expect(JobTransaction).to receive(:delete_all_complete_jobs).with(created_before: Time.now - (4 - i).months).and_return(deleted_counts[i]).ordered
      end
    end
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[0]} JobTransactions for completed jobs from 4 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[1]} JobTransactions for completed jobs from 3 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[2]} JobTransactions for completed jobs from 2 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[3]} JobTransactions for completed jobs from 1 month ago./) }
  end
end

describe 'job_transaction:clean_up:orphans' do
  include ActiveSupport::Testing::TimeHelpers
  include_context "rake"

  let(:default_batch_size) { 50000 }
  let(:oldest_orphan_created_at) { nil }
  around(:each) do |example|
    travel_to(Time.now) do #freeze_time
      example.run
    end
  end
  before(:each) do
    expect(JobTransaction).to receive(:oldest_orphan_created_at).and_return(oldest_orphan_created_at)
  end

  context 'when oldest_orphan_created_at returns nil' do
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_orphans) }
    it { invoke_task(expected_stdout: /No orphan JobTransactions found./) }
  end

  context 'when oldest orphan from this month' do
    let(:oldest_orphan_created_at) { Time.now - 1.day }
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_orphans) }
    it { invoke_task(expected_stdout: /No orphan JobTransactions older than 1 month found./) }
  end

  context 'when oldest orphan from 4 months ago' do
    let(:oldest_orphan_created_at) { Time.now - 4.month - 2.day }
    let(:deleted_counts) { Array.new(4) { Faker::Number.between(0, 999) } }
    before(:each) do
      4.times do |i|
        expect(JobTransaction).to receive(:delete_all_orphans).with(created_before: Time.now - (4 - i).months, limit: default_batch_size).and_return(deleted_counts[i]).ordered
      end
    end
    it { invoke_task(expected_stdout: /-\nDeleted #{deleted_counts[0]} orphan JobTransactions from 4 months ago./) }
    it { invoke_task(expected_stdout: /-\nDeleted #{deleted_counts[1]} orphan JobTransactions from 3 months ago./) }
    it { invoke_task(expected_stdout: /-\nDeleted #{deleted_counts[2]} orphan JobTransactions from 2 months ago./) }
    it { invoke_task(expected_stdout: /-\nDeleted #{deleted_counts[3]} orphan JobTransactions from 1 month ago./) }
  end

  context 'with BATCH_SIZE' do
    include_context 'with env_override'
    let(:batch_size) { 2 }
    let(:env_override) { {
      'BATCH_SIZE' => batch_size
    } }
    let(:a_month_ago) { Time.now - 1.month }
    let(:oldest_orphan_created_at) { a_month_ago - 3.day }
    let(:deleted_count) { 5 }
    before(:each) do
      expect(JobTransaction).to receive(:delete_all_orphans).with(created_before: a_month_ago, limit: batch_size).and_return(batch_size).ordered
      expect(JobTransaction).to receive(:delete_all_orphans).with(created_before: a_month_ago, limit: batch_size).and_return(batch_size).ordered
      expect(JobTransaction).to receive(:delete_all_orphans).with(created_before: a_month_ago, limit: batch_size).and_return(1).ordered
    end
    it { invoke_task(expected_stdout: /---\nDeleted #{deleted_count} orphan JobTransactions from 1 month ago./) }
  end
end

describe 'job_transaction:clean_up:logical_orphans' do
  include ActiveSupport::Testing::TimeHelpers
  include_context "rake"

  let(:oldest_logical_orphan_created_at) { nil }
  around(:each) do |example|
    travel_to(Time.now) do #freeze_time
      example.run
    end
  end
  before(:each) do
    expect(JobTransaction).to receive(:oldest_logical_orphan_created_at).and_return(oldest_logical_orphan_created_at)
  end

  context 'when oldest_logical_orphan_created_at returns nil' do
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_logical_orphans) }
    it { invoke_task(expected_stdout: /No logical orphan JobTransactions found./) }
  end

  context 'when oldest logical orphan from this month' do
    let(:oldest_logical_orphan_created_at) { Time.now - 1.day }
    before(:each) { expect(JobTransaction).not_to receive(:delete_all_logical_orphans) }
    it { invoke_task(expected_stdout: /No logical orphan JobTransactions older than 1 month found./) }
  end

  context 'when oldest logical orphan from 4 months ago' do
    let(:oldest_logical_orphan_created_at) { Time.now - 4.month - 2.day }
    let(:deleted_counts) { Array.new(4) { Faker::Number.between(0, 1000) } }
    before(:each) do
      4.times do |i|
        expect(JobTransaction).to receive(:delete_all_logical_orphans).with(created_before: Time.now - (4 - i).months).and_return(deleted_counts[i]).ordered
      end
    end
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[0]} logical orphan JobTransactions from 4 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[1]} logical orphan JobTransactions from 3 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[2]} logical orphan JobTransactions from 2 months ago./) }
    it { invoke_task(expected_stdout: /Deleted #{deleted_counts[3]} logical orphan JobTransactions from 1 month ago./) }
  end
end

describe 'job_transaction:clean_up:all' do
  include ActiveSupport::Testing::TimeHelpers
  include_context "rake"

  let(:default_batch_size) { 50000 }
  let(:a_month_ago) { Time.now - 1.month }
  let(:just_over_a_month_ago) { Time.now - 1.month - 3.day }
  around(:each) do |example|
    travel_to(Time.now) do #freeze_time
      example.run
    end
  end

  it 'calls clean_up tasks in the correct order' do
    expect(JobTransaction).to receive(:oldest_completed_at).and_return(just_over_a_month_ago).ordered
    expect(JobTransaction).to receive(:delete_all_complete_jobs).with(created_before: a_month_ago).and_return(1).ordered
    expect(JobTransaction).to receive(:oldest_orphan_created_at).and_return(just_over_a_month_ago).ordered
    expect(JobTransaction).to receive(:delete_all_orphans).with(created_before: a_month_ago, limit: default_batch_size).and_return(1).ordered
    expect(JobTransaction).to receive(:oldest_logical_orphan_created_at).and_return(just_over_a_month_ago).ordered
    expect(JobTransaction).to receive(:delete_all_logical_orphans).with(created_before: a_month_ago).and_return(1).ordered
    invoke_task
  end
end
