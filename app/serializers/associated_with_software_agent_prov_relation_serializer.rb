class AssociatedWithSoftwareAgentProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: SoftwareAgentSerializer, key: :from
  has_one :relatable_to, serializer: ActivitySerializer, key: :to
end
