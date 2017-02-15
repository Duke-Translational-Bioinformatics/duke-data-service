# InvalidatedByActivityProvRelation is a ProvRelation through Single Table inheritance

class InvalidatedByActivityProvRelation < ProvRelation
  # InvalidatedByActivityProvRelation requires relationship_type 'was-invalidated-by'
  # which maps to a Graph::WasInvalidatedBy graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "InvalidatedByActivityProvRelation must be from a FileVersion" }
  validates :relationship_type, inclusion: { in: %w(was-invalidated-by),
    message: "InvalidatedByActivityProvRelation relationship_type must be 'was-invalidated-by'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(Activity),
    message: "InvalidatedByActivityProvRelation must be to a Activity" }

  validate :relatable_from_must_be_deleted

  def relatable_from_must_be_deleted
    if relatable_from && !relatable_from.is_deleted
      errors.add(:relatable_from, "Invalidated Entity must be Deleted")
    end
  end

  def set_relationship_type
    self.relationship_type = 'was-invalidated-by'
  end

  def kind
    'dds-relation-was-invalidated-by'
  end
end
