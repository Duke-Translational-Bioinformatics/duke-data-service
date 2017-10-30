require 'rails_helper'
require 'sneakers/runner'
require 'yaml'
Dir[Rails.root.join('app/jobs/*.rb')].each { |f| require f }

describe "workers" do
  JobsRunner.workers_registry.each do |worker_key, worker_class|
    describe "workers:#{worker_key}:run" do
      include_context "rake"
      let(:task_name) { "workers:#{worker_key}:run" }
      let(:expected_job_class) { worker_class }

      it { expect(subject.prerequisites).to  include("environment") }
      it "calls JobsRunner#run with #{worker_class}" do
        mocked_jobs_runner = instance_double(JobsRunner)
        expect(JobsRunner).to receive(:new)
          .with(worker_class)
          .and_return(mocked_jobs_runner)
        expect(mocked_jobs_runner).to receive(:run).and_return(true)
        invoke_task
      end
    end
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

    context "with ENV['WORKERS_ALL_RUN_EXCEPT'] set" do
      let(:except_workers_array) {['index_documents', 'message_logger']}

      before do
        stub_const('ENV', {'WORKERS_ALL_RUN_EXCEPT' => except_workers_string})
        expect(JobsRunner).to receive(:all)
          .with(except: except_workers_array)
          .and_return(mocked_jobs_runner)
        expect(mocked_jobs_runner).to receive(:run).and_return(true)
      end

      context 'comma separated without spaces' do
        let(:except_workers_string) { "%s,%s" % except_workers_array }
        it { invoke_task }
      end

      context 'comma separated with spaces' do
        let(:except_workers_string) { " %s,  %s " % except_workers_array }
        it { invoke_task }
      end
    end
  end
end

describe 'Heroku ProcFile Rake Tasks' do
  subject {
    proc_file_path = Rails.root.join "ProcFile"
    proc_file = YAML.load_file(proc_file_path)
    proc_file.values.map { |v| v.split("\s").last }.sort
  }
  let(:expected_jobs) {
    JobsRunner.workers_registry.keys.map {|v| "workers:#{v}:run" }.sort
  }

  it { is_expected.to include(*expected_jobs) }
end
