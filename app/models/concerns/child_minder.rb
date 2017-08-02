module ChildMinder
  extend ActiveSupport::Concern

  included do
    around_update :manage_children
  end

  def manage_children
    newly_deleted = is_deleted_changed? && is_deleted?
    yield
    if has_children? && newly_deleted
      (1..paginated_children.total_pages).each do |page|
        ChildDeletionJob.perform_later(
          ChildDeletionJob.initialize_job(self),
          self,
          page
        )
      end
    end
  end

  def has_children?
    children.count > 0
  end

  def delete_children(page)
    paginated_children(page).each do |child|
      child.current_transaction = current_transaction if child.class.include? ChildMinder
      child.update(is_deleted: true)
    end
  end

  private

  def paginated_children(page=1)
    children.page(page).per(Rails.application.config.max_children_per_job)
  end
end
