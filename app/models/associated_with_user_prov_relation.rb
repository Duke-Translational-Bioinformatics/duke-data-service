# AssociatedWithUserProvRelation is a ProvRelation through Single Table inheritance

class AssociatedWithUserProvRelation < AssociatedWithProvRelation
  # AssociatedWithUserProvRelation requires relationship_type 'was-associated-with'
  # which maps to a Graph::WasAssociatedWith graphed relationship
  validates :relationship_type, inclusion: { in: %w(was-associated-with),
    message: "AssociatedWithUserProvRelation relationship_type must be 'was-associated-with'" },
    allow_nil: true
  validates :relatable_from_type, inclusion: { in: %w(User),
    message: "AssociatedWithUserProvRelation must be from a User" }
  validates :relatable_to_type, inclusion: { in: %w(Activity),
    message: "AssociatedWithUserProvRelation must be to an Activity" }
end
