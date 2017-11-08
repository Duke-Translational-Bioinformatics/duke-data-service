class AttributedToUserProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: FileVersionSerializer, key: :from
  has_one :relatable_to, serializer: UserSerializer, key: :to
end
