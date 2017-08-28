module TrashableModel
  extend ActiveSupport::Concern

  included do
    validate :can_be_purged#, if: :is_purged_changed?
  end

  private
  def can_be_purged
    if is_purged? && !is_deleted?
      errors.add(:is_purged, "cannot be set to true if object is not already deleted")
    end
  end
end
