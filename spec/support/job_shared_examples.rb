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
    except_queue: '',
    except_exchange: ''
  |

  before do
    ENV['CLOUDAMQP_URL'] = Faker::Internet.slug
    mocked_bunny_session = instance_double(BunnyMock::Session)
    [
      ApplicationJob.opts[:exchange],
      ApplicationJob.opts[:retry_error_exchange],
      ApplicationJob.distributor_exchange_name
    ].each do |this_exchange|
      should_exist = this_exchange != except_exchange
      allow(mocked_bunny_session).to receive(:exchange_exists?)
        .with(this_exchange)
        .and_return(should_exist)
    end

    application_job_workers = (ApplicationJob.descendants.collect {|d|
      [d.queue_name, "#{d.queue_name}-retry"]
    }).flatten.uniq
    [
      MessageLogWorker.new.queue.name,
      "#{MessageLogWorker.new.queue.name}-retry",
      ApplicationJob.opts[:retry_error_exchange]
    ].concat(application_job_workers)
    .each do |this_queue|
      should_exist = this_queue != except_queue
      allow(mocked_bunny_session).to receive(:queue_exists?)
        .with(this_queue)
        .and_return(should_exist)
    end
    allow(ApplicationJob).to receive(:conn).and_return(mocked_bunny_session)
  end
end

shared_examples 'it requires queue' do |expected_queue|
  include_context 'expected bunny exchanges and queues', except_queue: expected_queue
  it_behaves_like 'a status error', "queue is missing expected queue #{expected_queue}"
end

shared_examples 'it requires exchange' do |expected_exchange|
  include_context 'expected bunny exchanges and queues', except_exchange: expected_exchange
  it_behaves_like 'a status error', "queue is missing expected exchange #{expected_exchange}"
end
