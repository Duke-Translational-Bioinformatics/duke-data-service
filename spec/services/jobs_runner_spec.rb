require 'rails_helper'

RSpec.describe JobsRunner do
  subject { described_class.new(initialized_with) }
  let(:initialized_with) { sneakers_worker }
  let(:sneakers_worker) { Class.new { include Sneakers::Worker } }
  let(:mocked_sneakers_runner) { instance_double(Sneakers::Runner) }
  let(:application_job_class) { Class.new(ApplicationJob) }
  let(:job_wrapper) { application_job_class.job_wrapper }

  include_context 'with sneakers'

  describe '#run' do
    it { is_expected.to respond_to(:run) }

    it 'runs the job with Sneakers::Runner' do
      expect(Sneakers::Runner).to receive(:new)
        .with([sneakers_worker])
        .and_return(mocked_sneakers_runner)
      expect(mocked_sneakers_runner).to receive(:run).and_return(true)
      expect{subject.run}.not_to raise_error
    end

    context 'when initialized with an ApplicationJob' do
      let(:initialized_with) { application_job_class }

      it 'runs the ApplicationJob::job_wrapper with Sneakers::Runner' do
        expect(application_job_class).to receive(:job_wrapper)
          .and_return(job_wrapper)
        expect(Sneakers::Runner).to receive(:new)
          .with([job_wrapper])
          .and_return(mocked_sneakers_runner)
        expect(mocked_sneakers_runner).to receive(:run).and_return(true)
        expect{subject.run}.not_to raise_error
      end
    end

    context 'when initialized with an Array' do
      let(:another_sneakers_worker) { Class.new { include Sneakers::Worker } }
      let(:initialized_with) { [sneakers_worker, another_sneakers_worker, application_job_class] }

      it 'runs both jobs with Sneakers::Runner' do
        expect(application_job_class).to receive(:job_wrapper)
          .and_return(job_wrapper)
        expect(Sneakers::Runner).to receive(:new)
          .with([sneakers_worker, another_sneakers_worker, job_wrapper])
          .and_return(mocked_sneakers_runner)
        expect(mocked_sneakers_runner).to receive(:run).and_return(true)
        expect{subject.run}.not_to raise_error
      end
    end
  end

  describe '::workers_registry' do
    it { expect(described_class).to respond_to(:workers_registry) }
    it { expect(described_class.workers_registry).to be_a Hash }
    it {
      expect(described_class.workers_registry).to eq({
        message_logger: MessageLogWorker,
        initialize_project_storage: ProjectStorageProviderInitializationJob,
        delete_children: ChildDeletionJob,
        index_documents: ElasticsearchIndexJob
      })
    }
  end
end
