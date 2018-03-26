class UsedProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: ActivitySerializer, key: :from
  has_one :relatable_to, serializer: FileVersionSerializer, key: :to
end
