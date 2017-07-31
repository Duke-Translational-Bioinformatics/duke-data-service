class ChildDeletionJob < ApplicationJob
  queue_as :child_deletion

  def perform(job_transaction, parent, page)
    self.class.start_job(job_transaction)
    parent.paginated_children(page).each do |child|
      child.current_transaction = job_transaction if child.class.include? ChildMinder
      child.update(is_deleted: true)
    end
    self.class.complete_job(job_transaction)
  end
end
