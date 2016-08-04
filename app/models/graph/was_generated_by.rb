class Graph::WasGeneratedBy
  include Neo4j::ActiveRel
  include Graphed::Model

  property :model_id
  property :model_kind
  from_class 'Graph::FileVersion'
  to_class 'Graph::Activity'
  type 'WasGeneratedBy'
  creates_unique
end
