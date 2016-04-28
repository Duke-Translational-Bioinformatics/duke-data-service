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

  def graph_relation(rel_type, from_model, to_model)
    from_node = from_model.graph_node
    to_node = to_model.graph_node
    graphed_relationship = from_node.query_as(:from)
      .match("from-[r:#{rel_type}]->to")
      .where('to.model_id = {m_id}')
      .params(m_id: to_model.id)
      .pluck(:r).first
    unless graphed_relationship
      graphed_relationship = "Graph::#{rel_type}".constantize.create(from_node: from_node, to_node: to_node)
    end
    graphed_relationship
  end

  def delete_graph_relation
    self.graph_relation.destroy
  end
end
