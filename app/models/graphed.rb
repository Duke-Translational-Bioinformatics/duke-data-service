module Graphed
  def graph_node(node_name=nil)
    node_name ||= self.class.name
    node_class = "Graph::#{node_name}"
    node = node_class.constantize.find_by(model_id: id, model_kind: kind)
    unless node
      node = node_class.constantize.create(model_id: id, model_kind: kind)
    end
    node
  end
end
