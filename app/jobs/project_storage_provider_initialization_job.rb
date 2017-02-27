class ProjectStorageProviderInitializationJob < ApplicationJob
  queue_as :project_storage_provider_initialization

  def perform(storage_provider:, project:)
    storage_provider.put_container(project.id)
  end
end
