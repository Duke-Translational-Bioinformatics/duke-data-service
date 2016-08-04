class ProvenanceGraphRelationship
  include ActiveModel::Serialization
  include Comparable

  attr_reader :id, :type, :start_node, :end_node
  attr_accessor :properties

  def initialize(relationship)
    @id = relationship.model_id
    @type = relationship.type
    @start_node = relationship.from_node.model_id
    @end_node = relationship.to_node.model_id
    @properties = nil
  end

  def <=>(other_provenance)
    [self.id, self.type, self.start_node, self.end_node, self.properties] <=> [other_provenance.id, other_provenance.type, other_provenance.start_node, other_provenance.end_node, other_provenance.properties]
  end
end
