class DerivedFromFileVersionProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: FileVersionSerializer, root: :from
  has_one :relatable_to, serializer: FileVersionSerializer, root: :to
end
