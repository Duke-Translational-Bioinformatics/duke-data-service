class Graph::WasDerivedFrom
  include Graphed::RelModel

  property :model_id
  property :model_kind
  from_class 'Graph::FileVersion'
  to_class 'Graph::FileVersion'
  type 'WasDerivedFrom'
  creates_unique
end
