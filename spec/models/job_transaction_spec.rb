require 'rails_helper'

RSpec.describe JobTransaction, type: :model do
  subject { FactoryBot.create(:job_transaction, :transactionable_dummy) }

  # Transactionable objects automaticalaly create JobTransactions
  # Use :transactionable_dummy trait to create fewer objects.
  it { expect(subject.transactionable).not_to respond_to :job_transactions }

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
      let(:complete_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'complete') }
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

  describe '.delete_all_complete_jobs' do
    let(:delete_all_complete_jobs) { described_class.delete_all_complete_jobs }
    it { expect(described_class).to respond_to(:delete_all_complete_jobs).with(0).arguments }
    it { expect(described_class).to respond_to(:delete_all_complete_jobs).with_keywords(:created_before) }
    it { expect(delete_all_complete_jobs).to eq 0 }

    context 'with multiple completed' do
      let(:complete_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'complete') }
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-3) }

      context 'created_before last completed' do
        let(:delete_all_complete_jobs) { described_class.delete_all_complete_jobs(created_before: complete_jobs.last.created_at) }
        it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-2) }
      end
    end

    context 'with multiple completed and referencing request ids' do
      let(:request_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy) }
      let(:complete_jobs) do
        request_jobs.collect do |i|
          FactoryBot.create(:job_transaction, :transactionable_dummy, state: 'complete', request_id: i.request_id)
        end
      end
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-3) }

      context 'created_before last completed' do
        let(:delete_all_complete_jobs) { described_class.delete_all_complete_jobs(created_before: complete_jobs.last.created_at) }
        it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-2) }
      end
    end

    context 'with multiple completed, referencing request ids and keys' do
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy) }
      let(:complete_jobs) do
        initial_jobs.collect do |i|
          FactoryBot.create(:job_transaction, state: 'complete', request_id: i.request_id, key: i.key, transactionable: i.transactionable)
        end
      end
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-6) }

      context 'created_before last completed' do
        let(:delete_all_complete_jobs) { described_class.delete_all_complete_jobs(created_before: complete_jobs.last.created_at) }
        it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-4) }
      end
    end

    context 'with multiple completed, referencing request ids and keys, different transactionables' do
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy) }
      let(:complete_jobs) do
        initial_jobs.collect do |i|
          FactoryBot.create(:job_transaction, :transactionable_dummy, state: 'complete', request_id: i.request_id, key: i.key)
        end
      end
      before(:each) do
        expect(complete_jobs).to be_a Array
      end
      it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-3) }

      context 'created_before last completed' do
        let(:delete_all_complete_jobs) { described_class.delete_all_complete_jobs(created_before: complete_jobs.last.created_at) }
        it { expect{delete_all_complete_jobs}.to change{JobTransaction.count}.by(-2) }
      end
    end
  end

  describe '.oldest_orphan_created_at' do
    let(:oldest_orphan_created_at) { described_class.oldest_orphan_created_at }
    it { expect(described_class).to respond_to(:oldest_orphan_created_at) }
    it { expect(oldest_orphan_created_at).to be_nil }

    context 'with multiple orphans' do
      let(:orphan_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      let(:orphan_times) { orphan_jobs.collect {|j| j.created_at} }
      before(:each) do
        expect(orphan_jobs).to be_a Array
        orphan_jobs.each {|j| expect(j.reload).to be_truthy}
      end
      it { expect(orphan_times.uniq).to eq orphan_times }
      it { expect(orphan_times.sort).to eq orphan_times }
      it { expect(oldest_orphan_created_at).to eq orphan_times.first }

      it 'ignores non-orphans' do
        FactoryBot.create(:job_transaction, transactionable: orphan_jobs.first.transactionable, request_id: orphan_jobs.first.request_id)
        expect(oldest_orphan_created_at).to eq orphan_times.second
      end

      it 'ignores logical orphans' do
        FactoryBot.create(:job_transaction, transactionable: orphan_jobs.first.transactionable, request_id: orphan_jobs.first.request_id, state: 'updated')
        expect(oldest_orphan_created_at).to eq orphan_times.second
      end
    end
  end

  describe '.oldest_logical_orphan_created_at' do
    let(:oldest_logical_orphan_created_at) { described_class.oldest_logical_orphan_created_at }
    it { expect(described_class).to respond_to(:oldest_logical_orphan_created_at) }
    it { expect(oldest_logical_orphan_created_at).to be_nil }

    context 'with multiple orphans' do
      let(:orphan_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      let(:orphan_times) { orphan_jobs.collect {|j| j.created_at} }
      before(:each) do
        expect(orphan_jobs).to be_a Array
        orphan_jobs.each {|j| expect(j.reload).to be_truthy}
      end
      it { expect(orphan_times.uniq).to eq orphan_times }
      it { expect(orphan_times.sort).to eq orphan_times }
      it { expect(oldest_logical_orphan_created_at).to eq orphan_times.first }

      it 'ignores non-orphans' do
        FactoryBot.create(:job_transaction, transactionable: orphan_jobs.first.transactionable, request_id: orphan_jobs.first.request_id)
        expect(oldest_logical_orphan_created_at).to eq orphan_times.second
      end

      it 'recognizes logical orphans' do
        FactoryBot.create(:job_transaction, transactionable: orphan_jobs.first.transactionable, request_id: orphan_jobs.first.request_id, state: 'updated')
        expect(oldest_logical_orphan_created_at).to eq orphan_times.first
      end
    end
  end

  describe '.delete_all_orphans' do
    let(:delete_all_orphans) { described_class.delete_all_orphans }
    it { expect(described_class).to respond_to(:delete_all_orphans).with(0).arguments }
    it { expect(described_class).to respond_to(:delete_all_orphans).with_keywords(:created_before) }
    it { expect(described_class).to respond_to(:delete_all_orphans).with_keywords(:limit) }
    it { expect(delete_all_orphans).to eq 0 }

    context 'with multiple orphans' do
      let(:orphan_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy) }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(orphan_jobs).to be_a Array
      end
      it { expect{delete_all_orphans}.to change{JobTransaction.count}.by(-3) }

      context 'created_before last orphan' do
        let(:delete_all_orphans) { described_class.delete_all_orphans(created_before: orphan_jobs.last.created_at) }
        it { expect{delete_all_orphans}.to change{JobTransaction.count}.by(-2) }
      end

      context 'limit to 1' do
        let(:delete_all_orphans) { described_class.delete_all_orphans(limit: 1) }
        it { expect{delete_all_orphans}.to change{JobTransaction.count}.by(-1) }
      end
    end

    context 'with matching request and transactionable ids' do
      let(:request_id) { SecureRandom.uuid }
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(initial_jobs).to be_a Array
        initial_jobs.each do |i|
          FactoryBot.create(:job_transaction, transactionable: i.transactionable, request_id: i.request_id)
        end
      end
      it { expect{delete_all_orphans}.not_to change{JobTransaction.count} }
    end

    context 'with matching request and transactionable ids and create/update state' do
      let(:request_id) { SecureRandom.uuid }
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(initial_jobs).to be_a Array
        initial_jobs.each do |i|
          FactoryBot.create(:job_transaction, transactionable: i.transactionable, request_id: i.request_id, state: 'updated')
        end
      end
      it { expect{delete_all_orphans}.not_to change{JobTransaction.count} }
    end
  end

  describe '.delete_all_logical_orphans' do
    let(:delete_all_logical_orphans) { described_class.delete_all_logical_orphans }
    it { expect(described_class).to respond_to(:delete_all_logical_orphans).with(0).arguments }
    it { expect(described_class).to respond_to(:delete_all_logical_orphans).with_keywords(:created_before) }
    it { expect(delete_all_logical_orphans).to eq 0 }

    context 'with multiple orphans' do
      let(:orphan_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy) }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(orphan_jobs).to be_a Array
      end
      it { expect{delete_all_logical_orphans}.not_to change{JobTransaction.count} }

      context 'created_before last orphan' do
        let(:delete_all_logical_orphans) { described_class.delete_all_logical_orphans(created_before: orphan_jobs.last.created_at) }
        it { expect{delete_all_logical_orphans}.not_to change{JobTransaction.count} }
      end
    end

    context 'with multiple logical orphans' do
      let(:orphan_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(orphan_jobs).to be_a Array
      end
      it { expect{delete_all_logical_orphans}.to change{JobTransaction.count}.by(-3) }

      context 'created_before last orphan' do
        let(:delete_all_logical_orphans) { described_class.delete_all_logical_orphans(created_before: orphan_jobs.last.created_at) }
        it { expect{delete_all_logical_orphans}.to change{JobTransaction.count}.by(-2) }
      end
    end

    context 'with matching request and transactionable ids' do
      let(:request_id) { SecureRandom.uuid }
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(initial_jobs).to be_a Array
        initial_jobs.each do |i|
          FactoryBot.create(:job_transaction, transactionable: i.transactionable, request_id: i.request_id)
        end
      end
      it { expect{delete_all_logical_orphans}.not_to change{JobTransaction.count} }
    end

    context 'with matching request and transactionable ids and create/update state' do
      let(:request_id) { SecureRandom.uuid }
      let(:initial_jobs) { FactoryBot.create_list(:job_transaction, 3, :transactionable_dummy, state: 'created') }
      before(:each) do
        expect(JobTransaction.count).to eq 0
        expect(initial_jobs).to be_a Array
        initial_jobs.each do |i|
          FactoryBot.create(:job_transaction, transactionable: i.transactionable, request_id: i.request_id, state: 'updated')
        end
      end
      it { expect{delete_all_logical_orphans}.to change{JobTransaction.count}.by(-6) }
    end
  end
end
