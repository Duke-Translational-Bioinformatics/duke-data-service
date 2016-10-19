class ProjectStorageProviderInitializationJob < ActiveJob::Base
  queue_as :default

  def perform(storage_provider:, project:)
    storage_provider.put_container(project.id)
  end
end
