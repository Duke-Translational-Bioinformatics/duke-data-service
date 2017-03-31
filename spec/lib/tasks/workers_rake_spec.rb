require 'rails_helper'
require 'sneakers/runner'
Dir[Rails.root.join('app/jobs/*.rb')].each { |f| require f }

describe "workers" do
  describe 'workers:message_logger:run' do
    include_context "rake"
    let(:task_name) { "workers:message_logger:run" }
    let(:expected_job_class) { MessageLogWorker }

    it { expect(subject.prerequisites).to  include("environment") }
    it_behaves_like 'a queued worker', :expected_job_class
  end

  describe 'workers:initialize_project_storage:run' do
    include_context "rake"
    let(:task_name) { "workers:initialize_project_storage:run" }
    let(:expected_job_class) { ProjectStorageProviderInitializationJob }

    it { expect(subject.prerequisites).to  include("environment") }
    it_behaves_like 'a queued job worker', :expected_job_class
  end

  describe 'workers:delete_children:run' do
    include_context "rake"
    let(:task_name) { "workers:delete_children:run" }
    let(:expected_job_class) { ChildDeletionJob }

    it { expect(subject.prerequisites).to  include("environment") }
    it_behaves_like 'a queued job worker', :expected_job_class
  end

  describe 'workers:index_documents:run' do
    include_context "rake"
    let(:task_name) { "workers:index_documents:run" }
    let(:expected_job_class) { ElasticsearchIndexJob }

    it { expect(subject.prerequisites).to  include("environment") }
    it_behaves_like 'a queued job worker', :expected_job_class
  end

  describe 'workers:all:run' do
    include_context "rake"
    let(:task_name) { "workers:all:run" }
    let(:mocked_jobs_runner) { instance_double(JobsRunner) }

    it { expect(subject.prerequisites).to  include("environment") }
    it {
      expect(JobsRunner).to receive(:all)
        .and_return(mocked_jobs_runner)
      expect(mocked_jobs_runner).to receive(:run).and_return(true)
      invoke_task
    }
  end
end
