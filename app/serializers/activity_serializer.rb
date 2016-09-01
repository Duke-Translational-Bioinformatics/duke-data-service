class ActivitySerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :kind,
              :id,
             :name,
             :description,
             :started_on,
             :ended_on,
             :is_deleted,
             :audit
end
