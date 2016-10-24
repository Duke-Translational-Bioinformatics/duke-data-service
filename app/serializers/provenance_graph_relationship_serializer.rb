class ProvenanceGraphRelationshipSerializer < ActiveModel::Serializer
  attributes :id, :type, :start_node, :end_node, :properties

  def properties
    if object.is_restricted?
      nil
    else
      ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
    end
  end
end
