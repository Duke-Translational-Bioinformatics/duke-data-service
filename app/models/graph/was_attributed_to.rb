class Graph::WasAttributedTo
  include Neo4j::ActiveRel
  include Graphed::Model

  property :model_id
  property :model_kind
  from_class 'Graph::FileVersion'
  type 'WasAttributedTo'
  to_class 'Graph::Agent'
  creates_unique
end
