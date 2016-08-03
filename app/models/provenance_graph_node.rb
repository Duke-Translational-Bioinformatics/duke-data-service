class ProvenanceGraphNode
  include ActiveModel::Serialization
  include Comparable

  attr_reader :id, :labels
  attr_accessor :properties

  def initialize(node)
    @id = node.model_id
    @labels = [ "#{ node.class.mapped_label_name }" ]
    @properties = nil
  end

  def <=>(other_provenance)
    [self.id, self.labels, self.properties] <=> [other_provenance.id, other_provenance.labels, other_provenance.properties]
  end
end
