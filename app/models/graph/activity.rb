class Graph::Activity
  include Graphed::NodeModel

  property :model_id
  property :model_kind
  property :is_deleted
  self.mapped_label_name = 'Activity'
end
