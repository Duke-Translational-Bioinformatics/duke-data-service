require 'rails_helper'
require 'sneakers/runner'
Dir[Rails.root.join('app/jobs/*.rb')].each { |f| require f }

describe "workers", :if => ENV['TEST_WORKERS'] do
  describe 'workers:initialize_project_storage:run' do
    include_context "rake"
    let(:task_name) { "workers:initialize_project_storage:run" }

    it { expect(subject.prerequisites).to  include("environment") }

    it {
      expected_workers = []
      this_worker = ProjectStorageProviderInitializationJob.job_wrapper
      expected_workers << this_worker
      expect(ProjectStorageProviderInitializationJob).to receive(:job_wrapper).and_return(this_worker)
      expect(expected_workers).not_to be_empty
      mocked_sneakers_runner = instance_double(Sneakers::Runner)
      expect(Sneakers::Runner).to receive(:new)
        .with(expected_workers)
        .and_return(mocked_sneakers_runner)
      expect(mocked_sneakers_runner).to receive(:run).and_return(true)
      invoke_task
    }
  end
end
