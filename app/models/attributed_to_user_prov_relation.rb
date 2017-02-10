# AttributedToUserProvRelation is a AttributedToProvRelation
# AttributedtoProvRelation is a ProvRelation through Single Table inheritance

class AttributedToUserProvRelation < AttributedToProvRelation
  # AttributedToUserProvRelation requires relationship_type 'was-attributed-to'
  # which maps to a Graph::WasAttributedTo graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "AttributedToUserProvRelation must be from a FileVersion" }
  validates :relationship_type, inclusion: { in: %w(was-attributed-to),
    message: "AttributedToUserProvRelation relationship_type must be 'was-attributed-to'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(User),
    message: "AttributedToUserProvRelation must be to a User" }

  def set_relationship_type
    self.relationship_type = 'was-attributed-to'
  end
end
