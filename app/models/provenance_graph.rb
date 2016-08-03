class ProvenanceGraph
  include ActiveModel::Serialization
  attr_reader :nodes, :relationships

  #pass a method with ProvenanceGraph.new(focus, 2, method(:method_name))
  def initialize(focus:, max_hops: nil, policy_scope:)
    @nodes = []
    @relationships = []
    @policy_scope = policy_scope
    @to_be_graphed = {
      nodes: {},
      relationships: {}
    }
    focus_node = focus.graph_node
    find_node(focus_node)

    if max_hops
      if max_hops > 1
        match_clause = "(focus)-[relationships*1..#{max_hops}]-(related)"
      else
        match_clause = "(focus)-[relationships]-(related)"
      end
    else
      # infinite hops
      match_clause = "(focus)-[relationships*]-(related)"
    end

    focus_node.query_as(:focus).match(match_clause).pluck("relationships","related").each do |r|
      relationships, related = r
      find_node(related)
      if relationships.is_a? Array
        relationships.each do |subr|
          find_relationship(subr)
        end
      else
        find_relationship(relationships)
      end
    end
    create_graph
  end

  private

  def create_graph()
    @to_be_graphed[:nodes].keys.each do |node_kind|
      @policy_scope.call(KindnessFactory.by_kind(node_kind)).where(id: @to_be_graphed[:nodes][node_kind].keys).each do |property|
        @to_be_graphed[:nodes][node_kind][property.id][:properties] = property
      end
      @nodes |= @to_be_graphed[:nodes][node_kind].values
    end

    @to_be_graphed[:relationships].keys.each do |rel_kind|
      @policy_scope.call(KindnessFactory.by_kind(rel_kind)).where(id: @to_be_graphed[:relationships][rel_kind].keys).each do |property|
        @to_be_graphed[:relationships][rel_kind][property.id][:properties] = property
      end
      @relationships |= @to_be_graphed[:relationships][rel_kind].values
    end
  end

  def find_node(node)
    @to_be_graphed[:nodes][node.model_kind] ||= {}
    return if @to_be_graphed[:nodes][node.model_kind][node.model_id]

    @to_be_graphed[:nodes][node.model_kind][node.model_id] = {
      id: node.model_id,
      labels: [ "#{ node.class.mapped_label_name }" ],
      properties: nil
    }
    true
  end

  def find_relationship(relationship)
    @to_be_graphed[:relationships][relationship.model_kind] ||= {}
    return if @to_be_graphed[:relationships][relationship.model_kind][relationship.model_id]

    @to_be_graphed[:relationships][relationship.model_kind][relationship.model_id] = {
      id: relationship.model_id,
      type: relationship.type,
      start_node: relationship.from_node.model_id,
      end_node: relationship.to_node.model_id,
      properties: nil
    }
    true
  end
end
