class AssociatedWithSoftwareAgentProvRelationSerializer < ProvRelationSerializer
  has_one :relatable_from, serializer: SoftwareAgentSerializer, root: :from
  has_one :relatable_to, serializer: ActivitySerializer, root: :to
end
