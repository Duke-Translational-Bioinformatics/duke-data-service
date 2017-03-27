module ChildMinder
  extend ActiveSupport::Concern

  included do
    around_update :manage_children
  end

  def manage_children
    newly_deleted = is_deleted_changed? && is_deleted?
    yield
    if has_children? && newly_deleted
      ChildDeletionJob.perform_later(
        ChildDeletionJob.initialize_job(self),
        self
      )
    end
  end

  def delete_children
    children.each do |child|
      child.update(is_deleted: true)
    end
  end

  def has_children?
    children.count > 0
  end
end
