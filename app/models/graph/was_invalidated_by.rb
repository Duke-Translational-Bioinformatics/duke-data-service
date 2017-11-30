class Graph::WasInvalidatedBy
  include Graphed::RelModel

  property :model_id
  property :model_kind
  from_class 'Graph::FileVersion'
  to_class 'Graph::Activity'
  type 'WasInvalidatedBy'
  creates_unique
end
