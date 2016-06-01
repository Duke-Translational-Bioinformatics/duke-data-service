class FingerprintSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :algorithm, :value, :audit
end
