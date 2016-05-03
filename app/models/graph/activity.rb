class Graph::Activity
  include Neo4j::ActiveNode
  property :model_id, index: :exact
  property :model_kind, index: :exact
  property :is_deleted, index: :exact
  self.mapped_label_name = 'Activity'
end
