shared_context 'with job runner' do |runner_class|
  let(:expected_job_wrapper) { runner_class.job_wrapper.new }
  before {
    expected_job_wrapper.run
    expected_job_wrapper.stop
  }
end

shared_examples 'an ElasticsearchIndexJob' do |container_sym|
  it {
    expect{described_class.perform_now}.to raise_error(ArgumentError)
  }
  before {
    ActiveJob::Base.queue_adapter = :test
  }
  include_context 'with job runner', described_class

  context 'update' do
    let(:existing_container) { FactoryGirl.create(container_sym) }
    let(:job_transaction) { described_class.initialize_job(existing_container) }
    context 'perform_now' do
      include_context 'tracking job', :job_transaction
      it {
        expect(existing_container).to be_persisted
        mocked_proxy = double()
        expect(mocked_proxy).to receive(:update_document)
        expect(existing_container).to receive(:__elasticsearch__).and_return(mocked_proxy)
        ElasticsearchIndexJob.perform_now(job_transaction, existing_container, update: true)
      }
    end
  end

  context 'create' do
    let(:new_container) { FactoryGirl.create(container_sym) }
    let(:job_transaction) { described_class.initialize_job(new_container) }
    context 'perform_now' do
      include_context 'tracking job', :job_transaction
      it {
        expect(new_container).to be_persisted
        mocked_proxy = double()
        expect(mocked_proxy).to receive(:index_document)
        expect(new_container).to receive(:__elasticsearch__).and_return(mocked_proxy)
        ElasticsearchIndexJob.perform_now(job_transaction, new_container)
        job_transaction.reload
      }
    end
  end
end

shared_context 'expected bunny exchanges and queues' do |
    except_queue: nil,
    except_exchange: nil
  |

  if except_queue
    let(:reject_queue) { send(except_queue) }
  else
    let(:reject_queue) { '' }
  end

  if except_exchange
    let(:reject_exchange) { send(except_exchange) }
  else
    let(:reject_exchange) { '' }
  end

  before do
    ENV['CLOUDAMQP_URL'] = Faker::Internet.slug
    unless reject_exchange.empty?
      allow_any_instance_of(BunnyMock::Session).to receive(:exchange_exists?)
        .with(reject_exchange)
        .and_return(false)
    end

    unless reject_queue.empty?
      allow_any_instance_of(BunnyMock::Session).to receive(:queue_exists?)
        .with(reject_queue)
        .and_return(false)
    end
    [
      Sneakers::CONFIG[:exchange],
      Sneakers::CONFIG[:retry_error_exchange],
      ApplicationJob.distributor_exchange_name
    ].reject{|q| q == reject_exchange }.each do |this_exchange|
      allow_any_instance_of(BunnyMock::Session).to receive(:exchange_exists?)
        .with(this_exchange)
        .and_return(true)
    end

    application_job_workers = (ApplicationJob.descendants.collect {|d|
      [d.queue_name, "#{d.queue_name}-retry"]
    }).flatten.uniq

    [
      MessageLogWorker.new.queue.name,
      "#{MessageLogWorker.new.queue.name}-retry",
      Sneakers::CONFIG[:retry_error_exchange]
    ].concat(application_job_workers)
    .reject{|q| q == reject_queue }
    .each do |this_queue|
      allow_any_instance_of(BunnyMock::Session).to receive(:queue_exists?)
        .with(this_queue)
        .and_return(true)
    end
  end
end

shared_examples 'it requires queue' do |expected_queue|
  let(:status_error) { "queue is missing expected queue #{send(expected_queue)}" }
  include_context 'expected bunny exchanges and queues', except_queue: expected_queue
  it_behaves_like 'a status error', :status_error
end

shared_examples 'it requires exchange' do |expected_exchange|
  let(:status_error) { "queue is missing expected exchange #{send(expected_exchange)}" }
  include_context 'expected bunny exchanges and queues', except_exchange: expected_exchange
  it_behaves_like 'a status error', :status_error
end

shared_context 'tracking job' do |tracked_job_sym|
  let(:tracked_job) { send(tracked_job_sym) }
  before do
    expect(described_class).to receive(:start_job)
      .with(tracked_job)
      .and_call_original
    expect(described_class).to receive(:complete_job)
      .with(tracked_job)
      .and_call_original
  end
end

shared_examples 'a ChildDeletionJob' do |
    parent_sym,
    child_folder_sym,
    child_file_sym
  |
  let(:parent) { send(parent_sym) }
  let(:job_transaction) { described_class.initialize_job(parent) }
  let(:child_folder) { send(child_folder_sym) }
  let(:child_file) { send(child_file_sym) }
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  include_context 'with job runner', described_class
  before {
    ActiveJob::Base.queue_adapter = :test
  }

  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}child_deletion") }
  it {
    expect {
      described_class.perform_now
    }.to raise_error(ArgumentError)
    expect {
      described_class.perform_now(parent)
    }.to raise_error(ArgumentError)
  }

  context 'perform_now', :vcr do
    let(:child_job_transaction) { described_class.initialize_job(child_folder) }
    include_context 'tracking job', :job_transaction

    it {
      expect(child_folder).to be_persisted
      expect(child_file.is_deleted?).to be_falsey

      expect(described_class).to receive(:initialize_job)
        .with(child_folder)
        .and_return(child_job_transaction)
      expect(described_class).to receive(:perform_later)
        .with(child_job_transaction, child_folder).and_call_original

      described_class.perform_now(job_transaction, parent)
      expect(child_folder.reload).to be_truthy
      expect(child_folder.is_deleted?).to be_truthy
      expect(child_file.reload).to be_truthy
      expect(child_file.is_deleted?).to be_truthy
    }
  end
end

shared_examples 'a job_transactionable model' do
  it {
    is_expected.to respond_to('job_transactionable?')
    is_expected.to be_job_transactionable
    is_expected.to have_many(:job_transactions).with_foreign_key('transactionable_id')
  }
end
