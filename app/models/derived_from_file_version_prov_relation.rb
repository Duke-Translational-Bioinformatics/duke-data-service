# DerivedFromFileVersionProvRelation is a ProvRelation through Single Table inheritance

class DerivedFromFileVersionProvRelation < ProvRelation
  # DerivedFromFileVersionProvRelation requires relationship_type 'was-derived-from'
  # which maps to a Graph::WasDerivedFrom graphed relationship
  validates :relatable_from_type, inclusion: { in: %w(FileVersion),
    message: "DerivedFromFileVersionProvRelation must be from a FileVersion" }
  validates :relationship_type, inclusion: { in: %w(was-derived-from),
    message: "DerivedFromFileVersionProvRelation relationship_type must be 'was-derived-from'" },
    allow_nil: true
  validates :relatable_to_type, inclusion: { in: %w(FileVersion),
    message: "DerivedFromFileVersionProvRelation must be to a FileVersion" }

  def set_relationship_type
    self.relationship_type = 'was-derived-from'
  end

  def kind
    'dds-relation-was-derived-from'
  end
end
