class ProjectStorageProviderInitializationJob < ApplicationJob
  queue_as :project_storage_provider_initialization

  def perform(job_transaction:, storage_provider:, project:)
    self.class.start_job job_transaction
    storage_provider.put_container(project.id)
    project.update!(is_consistent: true)
    self.class.complete_job job_transaction
  end
end
