class PropertySerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :key, :label, :description, :type, :is_deprecated, :audit

  def type
    object.data_type
  end

  has_one :template, serializer: TemplatePreviewSerializer
end
