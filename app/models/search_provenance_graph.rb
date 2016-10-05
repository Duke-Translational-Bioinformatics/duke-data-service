class SearchProvenanceGraph < ProvenanceGraph
  #pass a method with ProvenanceGraph.new(focus, 2, method(:method_name))
  def initialize(focus:, max_hops: nil, policy_scope:)
    super(policy_scope)
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
end
