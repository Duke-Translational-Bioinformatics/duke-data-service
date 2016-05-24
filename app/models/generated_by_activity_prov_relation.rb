# GeneratedByActivityProvRelation is a ProvRelation through Single Table inheritance

class GeneratedByActivityProvRelation < ProvRelation
  # GeneratedByActivityProvRelation requires relationship_type 'was-generated-by'
  # which maps to a Graph::WasAttributedTo graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "GeneratedByActivityProvRelation must be from a FileVersion" }
  validates :relationship_type, inclusion: { in: %w(was-generated-by),
    message: "GeneratedByActivityProvRelation relationship_type must be 'was-generated-by'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(Activity),
    message: "GeneratedByActivityProvRelation must be to a Activity" }

  def set_relationship_type
    self.relationship_type = 'was-generated-by'
  end
end
