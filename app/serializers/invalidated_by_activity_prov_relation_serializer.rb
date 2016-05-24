class InvalidatedByActivityProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: FileVersionSerializer, root: :from
  has_one :relatable_to, serializer: ActivitySerializer, root: :to
end
