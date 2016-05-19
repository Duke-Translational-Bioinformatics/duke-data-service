module Graphed
  def create_graph_node(node_name=nil)
    node_name ||= self.class.name
    node_class = "Graph::#{node_name}"
    node_class.constantize.create(model_id: id, model_kind: kind)
  end

  def graph_node(node_name=nil)
    node_name ||= self.class.name
    node_class = "Graph::#{node_name}"
    node_class.constantize.find_by(model_id: id, model_kind: kind)
  end

  def delete_graph_node
    graph_node =  self.graph_node
    if graph_node
      self.graph_node.destroy
    end
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

  def create_graph_relation(rel_type, from_model, to_model)
    from_node = from_model.graph_node
    to_node = to_model.graph_node
    "Graph::#{rel_type}".constantize.create(from_node: from_node, to_node: to_node)
  end

  def graph_relation(rel_type, from_model, to_model)
    from_node = from_model.graph_node
    to_node = to_model.graph_node
    from_node.query_as(:from)
      .match("from-[r:#{rel_type}]->to")
      .where('to.model_id = {m_id}')
      .params(m_id: to_model.id)
      .pluck(:r).first
  end

  def delete_graph_relation
    graph_relation = self.graph_relation
    if graph_relation
      graph_relation.destroy
    end
  end
end
