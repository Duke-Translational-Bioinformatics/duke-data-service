class ProvenanceGraphRelationshipSerializer < ActiveModel::Serializer
  attributes :id, :type, :start_node, :end_node, :properties

  def properties
    if object.properties
      ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
    else
      nil
    end
  end
end
