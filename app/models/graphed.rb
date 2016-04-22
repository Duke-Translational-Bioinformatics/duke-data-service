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

  def delete_graph_node
    self.graph_node.destroy
  end

  def logically_delete_graph_node
    if self.is_deleted
      node = self.graph_node
      unless node.is_deleted
        node.is_deleted = self.is_deleted
        node.save
      end
    end
  end
end
