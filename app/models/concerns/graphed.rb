module Graphed
  module Base
    extend ActiveSupport::Concern

    included do
      include JobTransactionable
    end

    def graph_model_name
      self.class.name
    end

    def graph_model_class
      "Graph::#{graph_model_name}".constantize
    end
  end

  module Node
    extend ActiveSupport::Concern

    # These are models that get turned into Graph::* Neo4j::ActiveNode objects
    included do
      include Graphed::Base

      after_create :create_graph_node
      after_destroy :delete_graph_node
    end

    def create_graph_node
      graph_model_class.create(model_id: id, model_kind: kind)
    end

    def graph_node
      graph_model_class.find_by(model_id: id, model_kind: kind)
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
      include Graphed::Base

      after_create :create_graph_relation
      after_destroy :delete_graph_relation
      around_update :manage_graph_relation
    end

    def graph_model_type
      graph_model_name.underscore.dasherize
    end

    def manage_graph_relation
      newly_deleted = is_deleted_changed? && is_deleted?
      yield
      delete_graph_relation if newly_deleted
    end

    def graph_from_model
      raise NotImplementedError
    end

    def graph_to_model
      raise NotImplementedError
    end

    def graph_from_node
      graph_from_model.graph_node
    end

    def graph_to_node
      graph_to_model.graph_node
    end

    #These are ProvRelations that get turned into Graph::* Neo4j::ActiveRel relationships
    #between Graph::* Neo4j::ActiveNode objects
    def create_graph_relation(from_model, to_model)
      from_node = from_model.graph_node
      to_node = to_model.graph_node
      graph_model_class.create(
        model_id: id,
        model_kind: kind,
        from_node: from_node,
        to_node: to_node
      )
    end

    def graph_relation(from_model, to_model)
      from_node = from_model.graph_node
      from_node.query_as(:from)
        .match("(from)-[r:#{graph_model_name}]->(to)")
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
