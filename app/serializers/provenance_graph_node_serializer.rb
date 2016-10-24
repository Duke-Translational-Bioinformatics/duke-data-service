class ProvenanceGraphNodeSerializer < ActiveModel::Serializer
  attributes :id, :labels, :properties

  def properties
    if object.is_restricted?
      RestrictedObjectSerializer.new(object.properties)
    else
      ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
    end
  end
end
