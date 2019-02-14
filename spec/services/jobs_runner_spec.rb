require 'rails_helper'

RSpec.describe JobsRunner do
  subject { described_class.new(initialized_with) }
  let(:initialized_with) { sneakers_worker }
  let(:sneakers_worker) { Class.new { include Sneakers::Worker } }
  let(:mocked_sneakers_runner) { instance_double(Sneakers::Runner) }
  let(:job_class_name) {|example| "jobs_runner_spec#{example.metadata[:scoped_id].gsub(':','x')}_job".classify }
  let(:application_job_class) {
    Object.const_set(job_class_name, Class.new(ApplicationJob) do
      def self.should_be_registered_worker?
        false
      end
    end)
  }
  let(:workers_registry_hash) { {
    message_logger: MessageLogWorker,
    initialize_project_storage: ProjectStorageProviderInitializationJob,
    initialize_upload_storage: UploadStorageProviderInitializationJob,
    delete_children: ChildDeletionJob,
    index_documents: ElasticsearchIndexJob,
    update_project_container_elasticsearch: ProjectContainerElasticsearchUpdateJob,
    graph_persistence: GraphPersistenceJob,
    complete_upload: UploadCompletionJob,
    purge_upload: UploadStorageRemovalJob,
    purge_children: ChildPurgationJob,
    restore_children: ChildRestorationJob
  } }
  let(:registered_worker_classes) { workers_registry_hash.values }
  let(:expected_jobs) { ApplicationJob.descendants.select{|klass| klass.should_be_registered_worker? }.sort { |x,y| x.to_s <=> y.to_s } }

  it {
    expect(registered_worker_classes.sort { |x,y| x.to_s <=> y.to_s } ).to include(*expected_jobs)
    expect(registered_worker_classes).to include MessageLogWorker
    expect(described_class.workers_registry.values.sort { |x,y| x.to_s <=> y.to_s }).to include(*expected_jobs)
    expect(described_class.workers_registry.values).to include MessageLogWorker
  }

  shared_context 'with job_wrapper' do
    let(:job_wrapper) { application_job_class.job_wrapper }
    before do
      expect(application_job_class).to receive(:job_wrapper)
        .and_return(job_wrapper)
    end
  end

  include_context 'with sneakers'

  describe '::all' do
    it { expect(described_class).to respond_to(:all) }
    it { expect(described_class.all).to be_a described_class }
    it 'calls ::new with Array of registered worker classes' do
      expect(described_class).to receive(:new)
        .with(registered_worker_classes)
      expect{described_class.all}.not_to raise_error
    end

    context 'with :except keyword' do
      let(:except_worker_key) { workers_registry_hash.keys.sample }
      let(:except_worker_class) { workers_registry_hash[except_worker_key] }
      let(:permitted_worker_classes) { registered_worker_classes - [except_worker_class] }

      it 'raises an ArgumentError when except is not an array' do
        expect{described_class.all(except: except_worker_key)}.to raise_error(ArgumentError, 'keyword :except must be an array')
      end

      it 'omit registered worker associated to sym in :execpt array' do
        expect(described_class).to receive(:new)
          .with(permitted_worker_classes)
        expect{described_class.all(except: [except_worker_key])}.not_to raise_error
      end

      it 'omit registered worker associated to string in :execpt array' do
        expect(described_class).to receive(:new)
          .with(permitted_worker_classes)
        expect{described_class.all(except: [except_worker_key.to_s])}.not_to raise_error
      end
    end
  end

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
      include_context 'with job_wrapper'

      it 'runs the ApplicationJob::job_wrapper with Sneakers::Runner' do
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
      include_context 'with job_wrapper'

      it 'runs both jobs with Sneakers::Runner' do
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
      expect(described_class.workers_registry).to eq(workers_registry_hash)
    }
  end
end
