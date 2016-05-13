# AssociatedWithSoftwareAgentProvRelation is a ProvRelation through Single Table inheritance

class AssociatedWithSoftwareAgentProvRelation < ProvRelation
  # AssociatedWithSoftwareAgentProvRelation requires relationship_type 'was-associated-with'
  # which maps to a Graph::WasAssociatedWith graphed relationship
  validates :relationship_type, inclusion: { in: %w(was-associated-with),
    message: "AssociatedWithSoftwareAgentProvRelation relationship_type must be 'was-associated-with'" }
  validates :relatable_from_type, inclusion: { in: %w(SoftwareAgent),
    message: "AssociatedWithSoftwareAgentProvRelation must be from a SoftwareAgent" }
  validates :relatable_to_type, inclusion: { in: %w(Activity),
    message: "AssociatedWithSoftwareAgentProvRelation must be to an Activity" }
end
