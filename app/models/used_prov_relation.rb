# UsedProvRelation is a ProvRelation through Single Table inheritance

class UsedProvRelation < ProvRelation
  # UsedProvRelation requires relationship_type 'used' which maps to a Graph::Used graphed relationship
  validates :relationship_type, inclusion: { in: %w(used),
    message: "UsedProvRelation relationship_type must be 'used'" },
    allow_nil: true
  validates :relatable_from_type, inclusion: { in: %w(Activity),
    message: "UsedProvRelation must be from an Activity" }
  validates :relatable_to_type, inclusion: { in: %w(FileVersion),
    message: "UsedProvRelation must be to a FileVersion" }

  validate :using_activity, unless: :is_deleted

  def set_relationship_type
    self.relationship_type = 'used'
  end

  def using_activity
    if GeneratedByActivityProvRelation.where(
      relatable_from_id: relatable_to_id,
      relatable_to_id: relatable_from_id
      ).exists?
      errors.add(:relatable_from_id, "UsedProvRelation cannot be made from an Activity that has a GeneratedByActivityProvRelation to the used FileVersion")
    end
  end

  def kind
    'dds-relation-used'
  end
end
