class ChildRestorationJob < ApplicationJob
  queue_as :child_restoration

  def perform(job_transaction, parent, page)
    self.class.start_job(job_transaction)
    parent.current_transaction = job_transaction
    parent.restore_children(page)
    self.class.complete_job(job_transaction)
  end
end
