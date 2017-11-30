class Graph::FileVersion
  include Graphed::NodeModel

  property :model_id, index: :exact
  property :model_kind, index: :exact
  property :is_deleted, index: :exact
  self.mapped_label_name = 'FileVersion'
end
