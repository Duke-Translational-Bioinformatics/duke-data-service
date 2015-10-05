class Affiliation < ActiveRecord::Base
  audited
  after_save :update_project_etag
  after_destroy :update_project_etag

  belongs_to :user
  belongs_to :project
  belongs_to :project_role
  has_many :project_permissions, through: :project

  validates :user_id, presence: true, uniqueness: {scope: :project_id}
  validates :project_id, presence: true
  validates :project_role_id, presence: true

  private

  def update_project_etag
    last_audit = self.audits.last
    self.project.update(etag: SecureRandom.hex, audit_comment: "#{last_audit.comment} raised by: #{last_audit.id}")
    last_parent_audit = self.project.audits.last
    last_parent_audit.update(request_uuid: last_audit.request_uuid)
  end
end
