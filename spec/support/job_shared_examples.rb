shared_context 'with sneakers' do
  before(:each) do
    Sneakers.clear!
    Sneakers.configure(SNEAKERS_CONFIG_ORIGINAL.to_hash)
    unless ENV['TEST_WITH_BUNNY']
      allow_any_instance_of(Bunny::Session).to receive(:start).and_raise("Use BunnyMock when testing")
      Sneakers.configure(connection: BunnyMock.new)
    end
    ActiveJob::Base.queue_adapter = :sneakers
  end
end

shared_context 'with job runner' do |runner_class|
  let(:expected_job_wrapper) { runner_class.job_wrapper.new }
  before {
    expected_job_wrapper.run
    expected_job_wrapper.stop
  }
end

shared_context 'performs enqueued jobs' do |only: nil|
  around(:example) do |example|
    perform_enqueued_jobs(only: only) do
      example.run
    end
  end
end

shared_examples 'an ElasticsearchIndexJob' do |container_sym|
  it {
    expect{described_class.perform_now}.to raise_error(ArgumentError)
  }
  include_context 'with job runner', described_class

  context 'update' do
    let(:existing_container) { FactoryBot.create(container_sym) }
    let(:job_transaction) { described_class.initialize_job(existing_container) }
    let(:original_name) { existing_container.name }
    let(:changed_name) { 'changed name' }

    context 'perform_now' do
      include_context 'elasticsearch prep', [], []
      include_context 'tracking job', :job_transaction

      context 'index exists' do
        it {
          expect(existing_container).to be_persisted
          existing_container.__elasticsearch__.index_document
          Elasticsearch::Model.client.indices.flush
          expect(
            existing_container.class.search({
              query: {
                match: {
                  _id: existing_container.id
                }
              }
            }).first._source["name"]
          ).to eq(original_name)
          existing_container.name = changed_name
          ElasticsearchIndexJob.perform_now(job_transaction, existing_container, update: true)
          Elasticsearch::Model.client.indices.flush
          expect(
            existing_container.class.search({
              query: {
                match: {
                  _id: existing_container.id
                }
              }
            }).first._source["name"]
          ).to eq(changed_name)
        }
      end

      context 'index does not exist' do
        it {
          expect(existing_container).to be_persisted
          expect(existing_container.class.search({
            query: {
              match: {
                _id: existing_container.id
              }
            }
          }).count).to eq(0)
          existing_container.name = changed_name
          ElasticsearchIndexJob.perform_now(job_transaction, existing_container, update: true)
          Elasticsearch::Model.client.indices.flush
          expect(existing_container.class.search({
            query: {
              match: {
                _id: existing_container.id
              }
            }
          }).count).to eq(1)
          expect(
            existing_container.class.search({
              query: {
                match: {
                  _id: existing_container.id
                }
              }
            }).first._source["name"]
          ).to eq(changed_name)
        }
      end
    end
  end

  context 'create' do
    let(:new_container) { FactoryBot.create(container_sym) }
    let(:job_transaction) { described_class.initialize_job(new_container) }
    context 'perform_now' do
      include_context 'tracking job', :job_transaction
      it {
        expect(new_container).to be_persisted
        mocked_proxy = double()
        expect(mocked_proxy).to receive(:index_document)
        expect(new_container).to receive(:__elasticsearch__).and_return(mocked_proxy)
        ElasticsearchIndexJob.perform_now(job_transaction, new_container)
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
      allow(Sneakers::CONFIG[:connection]).to receive(:exchange_exists?)
        .with(reject_exchange)
        .and_return(false)
    end

    unless reject_queue.empty?
      allow(Sneakers::CONFIG[:connection]).to receive(:queue_exists?)
        .with(reject_queue)
        .and_return(false)
    end
    [
      Sneakers::CONFIG[:exchange],
      Sneakers::CONFIG[:retry_error_exchange],
      ApplicationJob.distributor_exchange_name
    ].reject{|q| q == reject_exchange }.each do |this_exchange|
      allow(Sneakers::CONFIG[:connection]).to receive(:exchange_exists?)
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
      allow(Sneakers::CONFIG[:connection]).to receive(:queue_exists?)
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

shared_context 'tracking failed job' do |tracked_job_sym|
  let(:tracked_job) { send(tracked_job_sym) }
  before do
    expect(described_class).to receive(:start_job)
      .with(tracked_job)
      .and_call_original
    expect(described_class).not_to receive(:complete_job)
      .with(tracked_job)
      .and_call_original
  end
end
