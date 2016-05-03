class Graph::Agent
  include Neo4j::ActiveNode
  property :model_id, index: :exact
  property :model_kind, index: :exact
  self.mapped_label_name = 'Agent'
end
