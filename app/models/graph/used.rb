class Graph::Used
  include Neo4j::ActiveRel

  from_class 'Graph::Activity'
  to_class 'Graph::FileVersion'
  type 'Used'
end
