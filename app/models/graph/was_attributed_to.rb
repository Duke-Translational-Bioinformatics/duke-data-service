class Graph::WasAttributedTo
  include Neo4j::ActiveRel


  from_class 'Graph::FileVersion'
  type 'WasAttributedTo'
  to_class 'Graph::Agent'
end
