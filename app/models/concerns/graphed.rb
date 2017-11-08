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

    def graph_hash
      {model_id: id, model_kind: kind}
    end

    def create_graph_node
      GraphPersistenceJob.perform_later(
        GraphPersistenceJob.initialize_job(self),
        graph_model_class.name,
        action: 'create',
        graph_hash: graph_hash
      )
    end

    def graph_node
      graph_model_class.find_by(graph_hash)
    end

    def graph_model_object
      graph_node
    end

    def delete_graph_node
      GraphPersistenceJob.perform_later(
        GraphPersistenceJob.initialize_job(self),
        graph_model_class.name,
        action: 'delete',
        graph_hash: graph_hash
      )
    end

    def logically_delete_graph_node
      GraphPersistenceJob.perform_later(
        GraphPersistenceJob.initialize_job(self),
        graph_model_class.name,
        action: 'update',
        graph_hash: graph_hash,
        attributes: {is_deleted: self.is_deleted}
      )
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

    def graph_hash
      {
        model_id: id,
        model_kind: kind,
        from_node: graph_from_model.graph_hash,
        to_node: graph_to_model.graph_hash
      }
    end

    #These are ProvRelations that get turned into Graph::* Neo4j::ActiveRel relationships
    #between Graph::* Neo4j::ActiveNode objects
    def create_graph_relation
      GraphPersistenceJob.perform_later(
        GraphPersistenceJob.initialize_job(self),
        graph_model_class.name,
        action: 'create',
        graph_hash: graph_hash
      )
    end

    def graph_relation
      graph_model_class.find_by_graph_hash(graph_hash)
    end

    def graph_model_object
      graph_relation
    end

    def delete_graph_relation
      GraphPersistenceJob.perform_later(
        GraphPersistenceJob.initialize_job(self),
        graph_model_class.name,
        action: 'delete',
        graph_hash: graph_hash
      )
    end
  end #Graphed::Relation

  module Model
    # these are Graph::* Neo4j objects
    def graphed_model(scope=nil)
      scope ||= KindnessFactory.by_kind(model_kind)
      scope.where(id: model_id).take
    end
  end #Graphed::Model

  module NodeModel
    extend ActiveSupport::Concern

    included do
      include Neo4j::ActiveNode
      include Graphed::Model
    end

    class_methods do
      def find_by_graph_hash(graph_hash)
        find_by(graph_hash)
      end

      def create_with_graph_hash(graph_hash)
        create(graph_hash)
      end
    end
  end #Graphed::NodeModel

  module RelModel
    extend ActiveSupport::Concern

    included do
      include Neo4j::ActiveRel
      include Graphed::Model
    end

    class_methods do
      def find_from_node(graph_hash)
        from_class.constantize.find_by(graph_hash[:from_node])
      end

      def find_to_node(graph_hash)
        to_class.constantize.find_by(graph_hash[:to_node])
      end

      def find_by_graph_hash(graph_hash)
        from_node = find_from_node(graph_hash)
        to_node = find_to_node(graph_hash)
        from_node.query_as(:from)
          .match("(from)-[r:#{type}]->(to)")
          .where('r.model_id = {r_id}')
          .where('r.model_kind = {r_kind}')
          .where('to.model_id = {m_id}')
          .params(
            r_id: graph_hash[:model_id],
            r_kind: graph_hash[:model_kind],
            m_id: to_node.model_id
          ).pluck(:r).first
      end

      def create_with_graph_hash(graph_hash)
        create(
          model_id: graph_hash[:model_id],
          model_kind: graph_hash[:model_kind],
          from_node: find_from_node(graph_hash),
          to_node: find_to_node(graph_hash)
        )
      end
    end
  end #Graphed::RelModel
end
