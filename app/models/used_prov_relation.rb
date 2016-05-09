# UsedProvRelation is a ProvRelation through Single Table inheritance

class UsedProvRelation < ProvRelation
  # UsedProvRelation requires relationship_type 'used' which maps to a Graph::Used graphed relationship
  validates :relationship_type, inclusion: { in: %w(used),
    message: "UsedProvRelation relationship_type must be 'used'" }
  validates :relatable_from_type, inclusion: { in: %w(Activity),
    message: "UsedProvRelation must be from an Activity" }
  validates :relatable_to_type, inclusion: { in: %w(FileVersion),
    message: "UsedProvRelation must be to a FileVersion" }
end
