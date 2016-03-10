class SoftwareAgentSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :audit, :name, :description, :repo_url, :is_deleted
end
