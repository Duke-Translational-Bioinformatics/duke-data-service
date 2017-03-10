shared_context 'with job runner' do |runner_class|
  let(:expected_job_wrapper) { runner_class.job_wrapper.new }
  before {
    expected_job_wrapper.run
    expected_job_wrapper.stop
  }
end

shared_examples 'an ElasticsearchIndexJob' do |container_sym|
  before {
    ActiveJob::Base.queue_adapter = :test
  }
  include_context 'with job runner', described_class

  context 'update' do
    context 'perform_now' do
      it {
        existing_container = FactoryGirl.create(container_sym)
        mocked_proxy = double()
        expect(mocked_proxy).to receive(:update_document)
        expect(existing_container).to receive(:__elasticsearch__).and_return(mocked_proxy)
        ElasticsearchIndexJob.perform_now(existing_container, update: true)
      }
    end
  end

  context 'create' do
    context 'perform_now' do
      it {
        new_container = FactoryGirl.create(container_sym)
        mocked_proxy = double()
        expect(mocked_proxy).to receive(:index_document)
        expect(new_container).to receive(:__elasticsearch__).and_return(mocked_proxy)
        ElasticsearchIndexJob.perform_now(new_container)
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
