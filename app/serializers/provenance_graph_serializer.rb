class ProvenanceGraphSerializer < ActiveModel::Serializer
  has_many :nodes, serializer: ProvenanceGraphNodeSerializer
  has_many :relationships, serializer: ProvenanceGraphRelationshipSerializer
end
