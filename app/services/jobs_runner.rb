require 'sneakers/runner'

class JobsRunner
  def initialize(job_class_or_array)
    @jobs = [job_class_or_array].flatten
    @jobs = @jobs.collect do |job|
      if job < ApplicationJob
        job.job_wrapper
      else
        job
      end
    end
  end

  def run
    Sneakers::Runner.new(@jobs).run
  end

  def self.workers_registry
    {
      message_logger: MessageLogWorker,
      initialize_project_storage: ProjectStorageProviderInitializationJob,
      delete_children: ChildDeletionJob,
      index_documents: ElasticsearchIndexJob
    }
  end
end
