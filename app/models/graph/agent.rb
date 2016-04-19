class Graph::Agent
  include Neo4j::ActiveNode
  property :model_id
  property :model_kind
  self.mapped_label_name = 'Agent'
end
