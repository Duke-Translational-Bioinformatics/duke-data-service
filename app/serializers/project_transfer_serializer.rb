class ProjectTransferSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :status, :status_comment, :audit

  has_many :to_users, serializer: UserPreviewSerializer
  has_one :from_user, serializer: UserPreviewSerializer
  has_one :project, serializer: ProjectPreviewSerializer
end
