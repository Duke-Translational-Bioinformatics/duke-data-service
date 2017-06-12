class ProjectSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :kind, :id, :name, :description, :is_deleted, :is_consistent, :audit

  def is_deleted
    object.is_deleted?
  end

  def is_consistent
    object.is_consistent?
  end
end
