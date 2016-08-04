class Graph::Used
  include Neo4j::ActiveRel
  include Graphed::Model

  property :model_id
  property :model_kind
  from_class 'Graph::Activity'
  to_class 'Graph::FileVersion'
  type 'Used'
  creates_unique
end
