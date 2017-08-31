module TrashableModel
  extend ActiveSupport::Concern

  included do
    validates :is_deleted, immutable: true, if: :is_purged_was
    validates :is_purged, immutable: true, if: :is_purged_was
    validate :can_be_purged
  end

  private
  def can_be_purged
    if is_purged? && !is_deleted?
      errors.add(:is_purged, "cannot be set to true if object is not already deleted")
    end
  end
end
