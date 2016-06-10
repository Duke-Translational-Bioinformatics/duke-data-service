class ProvRelationSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :kind, :id, :audit
end
