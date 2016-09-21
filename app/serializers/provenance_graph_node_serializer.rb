class ProvenanceGraphNodeSerializer < ActiveModel::Serializer
  attributes :id, :labels, :properties

  def properties
    if object.properties
      ActiveModel::Serializer.serializer_for(object.properties).new(object.properties)
    else
      {
        id: object.node.model_id,
        kind: object.node.model_kind,
        is_deleted: object.node.is_deleted ? "true" : "false"
      }
    end
  end
end
