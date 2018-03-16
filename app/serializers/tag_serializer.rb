class TagSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :label, :audit

  has_one :taggable, serializer: TaggableSerializer, key: :object

end
