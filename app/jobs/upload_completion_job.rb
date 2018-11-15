class UploadCompletionJob < ApplicationJob
  queue_as :upload_completion

  def perform(job_transaction, upload_id)
    self.class.start_job(job_transaction)
    upload = Upload.find(upload_id)
    upload.complete_and_validate_integrity
    self.class.complete_job(job_transaction)
  end
end
