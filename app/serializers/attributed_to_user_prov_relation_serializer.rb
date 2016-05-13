class AttributedToUserProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: FileVersionSerializer, root: :from
  has_one :relatable_to, serializer: UserSerializer, root: :to
end
