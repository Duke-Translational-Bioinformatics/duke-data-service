class ProvenanceGraphRelationshipSerializer < ActiveModel::Serializer
  attributes :id, :type, :start_node, :end_node, :properties

  def properties
    ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
  end
end
