class Project < ActiveRecord::Base
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

  def audit
    creation_audit = audits.where(action: "create").last
    last_update_audit = audits.where(action: "update").last
    delete_audit = audits.where(action: "destroy").last
    creator = creation_audit ?
        User.where(id: creation_audit.user_id).first :
        nil
    last_updator = last_update_audit ?
        User.where(id: last_update_audit.user_id).first :
        nil
    deleter = delete_audit ?
        User.where(id: delete_audit.user_id).first :
        nil
    {
      created_on: creation_audit ? creation_audit.created_at : nil,
      created_by: creator ? creator.audited_user_info : nil,
      last_updated_on: last_update_audit ? last_update_audit.created_at : nil,
      last_updated_by: last_updator ? last_updator.audited_user_info : nil,
      deleted_on: delete_audit ? delete_audit.created_at : nil,
      deleted_by: deleter ? deleter.audited_user_info : nil
    }
  end

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
