class Graph::FileVersion
  include Neo4j::ActiveNode
  property :model_id
  property :model_kind
  property :is_deleted
  self.mapped_label_name = 'FileVersion'
end
