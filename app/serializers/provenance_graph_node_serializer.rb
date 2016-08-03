class ProvenanceGraphNodeSerializer < ActiveModel::Serializer
  attributes :id, :labels, :properties

  def properties
    ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
  end
end
