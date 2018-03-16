class DerivedFromFileVersionProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: FileVersionSerializer, key: :from
  has_one :relatable_to, serializer: FileVersionSerializer, key: :to
end
