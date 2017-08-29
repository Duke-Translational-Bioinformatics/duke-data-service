module ChildMinder
  extend ActiveSupport::Concern

  included do
    around_update :manage_children
  end

  def manage_children
    newly_deleted = is_deleted_changed? && is_deleted?
    newly_restored = false
    newly_purged = false
    if self.class.include? TrashableModel
      newly_restored = is_deleted_changed? && !is_deleted?
      newly_purged = is_purged_changed? && is_purged
    end
    yield
    if has_children?
      if newly_deleted
        (1..paginated_children.total_pages).each do |page|
          ChildDeletionJob.perform_later(
            ChildDeletionJob.initialize_job(self),
            self,
            page
          )
        end
      end

      if newly_restored
        (1..paginated_children.total_pages).each do |page|
          ChildRestorationJob.perform_later(
            ChildRestorationJob.initialize_job(self),
            self,
            page
          )
        end
      end

      if newly_purged
        (1..paginated_children.total_pages).each do |page|
          ChildPurgationJob.perform_later(
            ChildPurgationJob.initialize_job(self),
            self,
            page
          )
        end
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

  def restore_children(page)
    if self.class.include? TrashableModel
      paginated_children(page).each do |child|
        child.current_transaction = current_transaction if child.class.include? ChildMinder
        child.update(is_deleted: false)
      end
    end
  end

  def purge_children(page)
    if self.class.include? TrashableModel
      paginated_children(page).each do |child|
        child.current_transaction = current_transaction if child.class.include? ChildMinder
        child.update(is_purged: true)
      end
    end
  end

  private

  def paginated_children(page=1)
    children.page(page).per(Rails.application.config.max_children_per_job)
  end
end
