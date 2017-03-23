module ChildMinder
  extend ActiveSupport::Concern

  included do
    around_update :manage_children
  end

  def manage_children
    newly_deleted = is_deleted_changed? && is_deleted?
    yield
    ChildDeletionJob.perform_later(
      ChildDeletionJob.initialize_job(self),
      self
    ) if newly_deleted
  end

  def delete_children
    children.each do |child|
      child.update(is_deleted: true)
    end
  end
end
