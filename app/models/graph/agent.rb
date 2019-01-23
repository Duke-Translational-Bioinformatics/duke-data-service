class Graph::Agent
  include Graphed::NodeModel

  property :model_id
  property :model_kind
  self.mapped_label_name = 'Agent'
end
