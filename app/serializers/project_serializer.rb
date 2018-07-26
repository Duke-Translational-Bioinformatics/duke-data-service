class ProjectSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :kind, :id, :name, :slug, :description, :is_deleted, :audit

  def is_deleted
    object.is_deleted?
  end

end
