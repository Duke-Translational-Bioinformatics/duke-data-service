# AttributedToSoftwareAgentProvRelation is a ProvRelation through Single Table inheritance

class AttributedToSoftwareAgentProvRelation < AttributedToProvRelation
  # AttributedToSoftwareAgentProvRelation requires relationship_type 'was-attributed-to'
  # which maps to a Graph::WasAttributedTo graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "AttributedToSoftwareAgentProvRelation must be from a FileVersion" }
  validates :relationship_type, inclusion: { in: %w(was-attributed-to),
    message: "AttributedToSoftwareAgentProvRelation relationship_type must be 'was-attributed-to'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(SoftwareAgent),
    message: "AttributedToSoftwareAgentProvRelation must be to a SoftwareAgent" }
end
