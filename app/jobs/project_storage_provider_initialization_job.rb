class ProjectStorageProviderInitializationJob < ApplicationJob
  queue_as self.name.underscore.gsub('_job','').to_sym

  def perform(storage_provider:, project:)
    storage_provider.put_container(project.id)
  end
end
