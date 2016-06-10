class Graph::WasDerivedFrom
  include Neo4j::ActiveRel

  from_class 'Graph::FileVersion'
  to_class 'Graph::FileVersion'
  type 'WasDerivedFrom'
end
