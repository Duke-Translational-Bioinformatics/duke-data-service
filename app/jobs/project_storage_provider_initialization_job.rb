class ProjectStorageProviderInitializationJob < ApplicationJob
  queue_as :project_storage_provider_initialization

  def perform(job_transaction:, project_storage_provider:)
    project = project_storage_provider.project
    storage_provider = project_storage_provider.storage_provider
    self.class.start_job job_transaction
    storage_provider.initialize_project(project)
    project.update!(is_consistent: true)
    self.class.complete_job job_transaction
  end
end
