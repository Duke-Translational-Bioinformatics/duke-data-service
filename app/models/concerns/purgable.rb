module Purgable
  extend ActiveSupport::Concern

  included do
    validates :is_deleted, immutable: true, if: :is_purged_was
    validates :is_purged, immutable: true, if: :is_purged_was
    validate :can_be_purged
    before_update :manage_purgation, if: :is_purged_changed?
  end

  def manage_purgation
    if is_purged?
      @child_job = ChildPurgationJob
    end
  end

  # ChildMinder method
  def purge_children(page)
    paginated_children(page).each do |child|
      child.current_transaction = current_transaction if child.class.include? JobTransactionable
      child.update(is_deleted: true, is_purged: true)
    end
  end

  def purge
    self.is_deleted = true
    self.is_purged = true
  end

  private
  def can_be_purged
    if is_purged? && !is_deleted?
      errors.add(:is_purged, "cannot be set to true if object is not already deleted")
    end
  end
end
