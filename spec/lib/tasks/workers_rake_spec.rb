require 'rails_helper'
require 'sneakers/runner'
Dir[Rails.root.join('app/jobs/*.rb')].each { |f| require f }

describe "workers" do
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
end
