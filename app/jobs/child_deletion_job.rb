class ChildDeletionJob < ApplicationJob
  queue_as :child_deletion

  def perform(job_transaction, parent, page)
    self.class.start_job(job_transaction)
    parent.current_transaction = job_transaction
    parent.delete_children(page)
    self.class.complete_job(job_transaction)
  end
end
