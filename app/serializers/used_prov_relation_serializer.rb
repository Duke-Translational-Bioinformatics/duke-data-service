class UsedProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: ActivitySerializer, root: :from
  has_one :relatable_to, serializer: FileVersionSerializer, root: :to
end
