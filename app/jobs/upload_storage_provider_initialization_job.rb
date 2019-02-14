class UploadStorageProviderInitializationJob < ApplicationJob
  queue_as :upload_storage_provider_initialization

  def perform(job_transaction:, storage_provider:, upload:)
    self.class.start_job job_transaction
    storage_provider.initialize_chunked_upload(upload)
    self.class.complete_job job_transaction
  end
end
