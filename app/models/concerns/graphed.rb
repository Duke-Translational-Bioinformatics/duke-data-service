module Graphed
  module Node
    # These are models that get turned into Graph::* Neo4j::ActiveNode objects
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
        if node && !node.is_deleted
          node.is_deleted = self.is_deleted
          node.save
        end
      end
    end
  end

  module Relation
    extend ActiveSupport::Concern

    included do
      after_create :create_graph_relation
      after_destroy :delete_graph_relation
      around_update :manage_graph_relation
    end

    def manage_graph_relation
      newly_deleted = is_deleted_changed? && is_deleted?
      yield
      delete_graph_relation if newly_deleted
    end

    #These are ProvRelations that get turned into Graph::* Neo4j::ActiveRel relationships
    #between Graph::* Neo4j::ActiveNode objects
    def create_graph_relation(rel_type, from_model, to_model)
      from_node = from_model.graph_node
      to_node = to_model.graph_node
      "Graph::#{rel_type}".constantize.create(
        model_id: id,
        model_kind: kind,
        from_node: from_node,
        to_node: to_node
      )
    end

    def graph_relation(rel_type, from_model, to_model)
      from_node = from_model.graph_node
      from_node.query_as(:from)
        .match("(from)-[r:#{rel_type}]->(to)")
        .where('r.model_id = {r_id}')
        .where('r.model_kind = {r_kind}')
        .where('to.model_id = {m_id}')
        .params(
          r_id: id,
          r_kind: kind,
          m_id: to_model.id
        ).pluck(:r).first
    end

    def delete_graph_relation
      this_relation = self.graph_relation
      if this_relation
        this_relation.destroy
      end
    end
  end #Graphed::Relation

  module Model
    # these are Graph::* Neo4j objects
    def graphed_model(scope=nil)
      scope ||= KindnessFactory.by_kind(model_kind)
      scope.where(id: model_id).take
    end
  end
end #Graphed::Model
