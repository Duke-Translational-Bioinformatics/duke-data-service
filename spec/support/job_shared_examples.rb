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
