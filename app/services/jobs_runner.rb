require 'sneakers/runner'

class JobsRunner
  def initialize(job_class_or_array)
    @jobs = [job_class_or_array].flatten
    @jobs = @jobs.collect(&method(:normalize_job))
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

  def self.all(except: [])
    raise ArgumentError.new("keyword :except must be an array") unless except.is_a? Array
    pruned_registry = self.workers_registry.reject {|k,v| except.include?(k)}
    self.new(pruned_registry.values)
  end

  private

  def normalize_job(job)
    if job < ApplicationJob
      job.job_wrapper
    else
      job
    end
  end
end
