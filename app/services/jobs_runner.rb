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
      initialize_upload_storage: UploadStorageProviderInitializationJob,
      delete_children: ChildDeletionJob,
      index_documents: ElasticsearchIndexJob,
      update_project_container_elasticsearch: ProjectContainerElasticsearchUpdateJob,
      graph_persistence: GraphPersistenceJob,
      complete_upload: UploadCompletionJob,
      purge_upload: UploadStorageRemovalJob,
      purge_children: ChildPurgationJob,
      restore_children: ChildRestorationJob
    }
  end

  def self.all(except: [])
    raise ArgumentError.new("keyword :except must be an array") unless except.is_a? Array
    self.new(self.pruned_registry(except).values)
  end

  private

  def self.pruned_registry(except)
    except = except.collect &:to_s
    self.workers_registry.reject {|k,v| except.include?(k.to_s)}
  end

  def normalize_job(job)
    if job < ApplicationJob
      job.job_wrapper
    else
      job
    end
  end
end
