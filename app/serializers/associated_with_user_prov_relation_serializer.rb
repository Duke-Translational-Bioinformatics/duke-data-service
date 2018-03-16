class AssociatedWithUserProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: UserSerializer, key: :from
  has_one :relatable_to, serializer: ActivitySerializer, key: :to
end
