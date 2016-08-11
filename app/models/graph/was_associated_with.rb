class Graph::WasAssociatedWith
  include Neo4j::ActiveRel
  include Graphed::Model

  property :model_id
  property :model_kind
  from_class 'Graph::Agent'
  to_class 'Graph::Activity'
  type 'WasAssociatedWith'
  creates_unique
end
