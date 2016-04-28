class Graph::WasAssociatedWith
  include Neo4j::ActiveRel

  from_class 'Graph::Agent'
  to_class 'Graph::Activity'
  type 'WasAssociatedWith'
end
