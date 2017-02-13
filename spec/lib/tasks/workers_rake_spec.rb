require 'rails_helper'
require 'sneakers/runner'
Dir[Rails.root.join('app/jobs/*.rb')].each { |f| require f }

describe "workers", :if => ENV['TEST_WORKERS'] do
  describe 'workers:run' do
    include_context "rake"
    let(:task_name) { "workers:run" }

    it { expect(subject.prerequisites).to  include("environment") }

    it {
      expected_workers = []
      ApplicationJob.descendants.each do |app_job_class|
        this_worker = app_job_class.job_wrapper
        expected_workers << this_worker
        expect(app_job_class).to receive(:job_wrapper).and_return(this_worker)
      end
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
