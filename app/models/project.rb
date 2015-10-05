class Project < ActiveRecord::Base
  include SerializedAudit
  audited
  after_create :set_project_admin

  belongs_to :creator, class_name: "User"
  has_many :folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  has_many :data_files

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true

  private
  def set_project_admin
    project_admin_role = AuthRole.where(id: 'project_admin').first
    if project_admin_role
      pp = self.project_permissions.create(
        user: self.creator,
        auth_role: project_admin_role,
        audit_comment: self.audits.last.comment
      )
    end
  end
end
