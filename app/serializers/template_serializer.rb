class TemplateSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :name, :label, :description, :is_deprecated, :audit
end
