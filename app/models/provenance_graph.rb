class ProvenanceGraph
  include ActiveModel::Serialization
  attr_reader :nodes, :relationships

  def initialize()
    @nodes = []
    @relationships = []
    @to_be_graphed = {
      nodes: {},
      relationships: {}
    }
  end

  private

  def create_graph()
    @to_be_graphed[:nodes].keys.each do |node_kind|
      @policy_scope.call(KindnessFactory.by_kind(node_kind)).where(id: @to_be_graphed[:nodes][node_kind].keys).each do |property|
        @to_be_graphed[:nodes][node_kind][property.id].properties = property
      end
      @nodes |= @to_be_graphed[:nodes][node_kind].values
    end

    @to_be_graphed[:relationships].keys.each do |rel_kind|
      @policy_scope.call(KindnessFactory.by_kind(rel_kind)).where(id: @to_be_graphed[:relationships][rel_kind].keys).each do |property|
        @to_be_graphed[:relationships][rel_kind][property.id].properties = property
      end
      @relationships |= @to_be_graphed[:relationships][rel_kind].values
    end
  end

  def find_node(node)
    @to_be_graphed[:nodes][node.model_kind] ||= {}
    return if @to_be_graphed[:nodes][node.model_kind][node.model_id]

    @to_be_graphed[:nodes][node.model_kind][node.model_id] = ProvenanceGraphNode.new(node)
    true
  end

  def find_relationship(relationship)
    @to_be_graphed[:relationships][relationship.model_kind] ||= {}
    return if @to_be_graphed[:relationships][relationship.model_kind][relationship.model_id]

    @to_be_graphed[:relationships][relationship.model_kind][relationship.model_id] = ProvenanceGraphRelationship.new(relationship)
    true
  end
end
