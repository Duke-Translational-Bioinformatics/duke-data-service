class UploadStorageRemovalJob < ApplicationJob
  queue_as :upload_storage_removal

  def perform(job_transaction, upload_id)
    self.class.start_job(job_transaction)
    upload = Upload.find(upload_id)
    upload.purge_storage
    self.class.complete_job(job_transaction)
  end
end
