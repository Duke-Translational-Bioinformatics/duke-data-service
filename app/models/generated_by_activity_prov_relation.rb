# GeneratedByActivityProvRelation is a ProvRelation through Single Table inheritance

class GeneratedByActivityProvRelation < ProvRelation
  # GeneratedByActivityProvRelation requires relationship_type 'was-generated-by'
  # which maps to a Graph::WasGeneratedBy graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "GeneratedByActivityProvRelation must be from a FileVersion" }

  validates :relatable_from_id, uniqueness: {
    scope: :relatable_to_id,
    case_sensitive: false,
    conditions: -> { where(is_deleted: false) }
  }, unless: :is_deleted

  validates :relationship_type, inclusion: { in: %w(was-generated-by),
    message: "GeneratedByActivityProvRelation relationship_type must be 'was-generated-by'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(Activity),
    message: "GeneratedByActivityProvRelation must be to a Activity" }

  def set_relationship_type
    self.relationship_type = 'was-generated-by'
  end
end
