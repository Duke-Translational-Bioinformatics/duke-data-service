class ProvenanceGraphNode
  include ActiveModel::Serialization
  include Comparable

  attr_reader :id, :labels, :node, :properties
  attr_accessor :restricted

  def initialize(node)
    @id = node.model_id
    @node = node
    @labels = [ "#{ node.class.mapped_label_name }" ]
    @properties = node.graphed_model
    @restricted = false
  end

  def is_restricted?
    self.restricted
  end

  def <=>(other_provenance)
    [self.id, self.labels, self.properties] <=> [other_provenance.id, other_provenance.labels, other_provenance.properties]
  end
end
