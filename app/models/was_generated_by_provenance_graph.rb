class WasGeneratedByProvenanceGraph < ProvenanceGraph
  #pass a method with ProvenanceGraph.new(focus, policy_scope: method(:method_name))
  def initialize(file_versions:, policy_scope:)
    super(policy_scope)
    match_clause = '(file_version:FileVersion)
    WHERE file_version.model_id IN {file_versions}
    OPTIONAL MATCH (file_version)-[generated_by:WasGeneratedBy]->(generating_activity:Activity)
    OPTIONAL MATCH (generating_activity)-[contributing:WasGeneratedBy|:Used]-(contributed:FileVersion)'

    Neo4j::Session.query.match(match_clause).params(
      file_versions: file_versions
    ).pluck(
      "file_version",
      "generated_by",
      "generating_activity",
      "contributing",
      "contributed").each do |file_version, generated_by, generating_activity, contributing, contributed|
      [file_version,generating_activity,contributed].reject{|n| n.nil? }.each do |node_to_find|
        find_node(node_to_find)
      end
      [generated_by, contributing].reject{|r| r.nil? }.each do |relationship_to_find|
        find_relationship(relationship_to_find)
      end
    end
    create_graph
  end
end
