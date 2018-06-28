module Restorable
  extend ActiveSupport::Concern

  included do
    before_update :manage_deletion_and_restoration, if: :is_deleted_changed?
  end

  def manage_deletion_and_restoration
    if is_deleted?
      @child_job = ChildDeletionJob
    elsif is_deleted_was && !is_deleted?
      @child_job = ChildRestorationJob
    #else
    end
  end

  # ChildMinder methods
  def restore_children(page)
    paginated_children(page).each do |child|
      child.current_transaction = current_transaction if child.class.include? JobTransactionable
      child.update(is_deleted: false)
    end
  end

  def delete_children(page)
    paginated_children(page).each do |child|
      child.current_transaction = current_transaction if child.class.include? JobTransactionable
      child.update(is_deleted: true)
    end
  end
end
