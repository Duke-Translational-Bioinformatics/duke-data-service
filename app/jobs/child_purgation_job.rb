class ChildPurgationJob < ApplicationJob
  queue_as :child_purgation

  def perform(job_transaction, parent, page)
    self.class.start_job(job_transaction)
    parent.current_transaction = job_transaction
    parent.purge_children(page)
    self.class.complete_job(job_transaction)
  end
end
