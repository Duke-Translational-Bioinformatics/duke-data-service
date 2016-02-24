class Project < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include SerializedAudit
  include Kinded
  audited

  belongs_to :creator, class_name: "User"
  has_many :folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  has_many :data_files
  has_many :children, -> { where parent_id: nil }, class_name: "Container", autosave: true
  has_many :containers

  validates :name, presence: true, uniqueness: {case_sensitive: false, conditions: -> { where(is_deleted: false) }}, unless: :is_deleted
  validates :description, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted

  def set_project_admin
    project_admin_role = AuthRole.where(id: 'project_admin').first
    if project_admin_role
      last_audit = self.audits.last
      pp = self.project_permissions.create(
        user: self.creator,
        auth_role: project_admin_role,
        audit_comment: last_audit.comment
      )
      pp
    end
  end

  def is_deleted=(val)
    if val
      children.each do |child|
        child.is_deleted = true
      end
    end
    super(val)
  end
end
