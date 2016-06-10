class AssociatedWithUserProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: UserSerializer, root: :from
  has_one :relatable_to, serializer: ActivitySerializer, root: :to
end
