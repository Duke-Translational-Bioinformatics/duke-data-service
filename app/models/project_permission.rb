class ProjectPermission < ActiveRecord::Base
  include RequestAudited
  default_scope { order('created_at DESC') }
  audited
  after_save :update_project_etag
  after_destroy :update_project_etag

  belongs_to :user
  belongs_to :project
  belongs_to :auth_role
  has_many :project_permissions, through: :project

  validates :user_id, presence: true, uniqueness: {scope: :project_id, case_sensitive: false}
  validates :project_id, presence: true
  validates :auth_role_id, presence: true

  private

  def update_project_etag
    if saved_changes?
      last_audit = self.audits.last
      new_comment = last_audit.comment ? last_audit.comment.merge({raised_by_audit: last_audit.id}) : {raised_by_audit: last_audit.id}
      self.project.update(etag: SecureRandom.hex, audit_comment: new_comment)
      last_parent_audit = self.project.audits.last
      last_parent_audit.update(request_uuid: last_audit.request_uuid)
    end
  end
end
