class ProvenanceGraphNodeSerializer < ActiveModel::Serializer
  attributes :id, :labels, :properties

  def properties
    if object.properties
      ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
    else
      nil
    end
  end
end
