class Folder < ActiveRecord::Base
  audited
  has_many :children, class_name: "Folder", foreign_key: "parent_id"
  belongs_to :project
	belongs_to :parent, class_name: "Folder"
  has_many :project_permissions, through: :project

  validates :name, presence: true
  validates :project_id, presence: true

  def virtual_path
    if parent
      [parent.virtual_path, self.name].join('/')
    else
      "/#{self.name}"
    end
  end

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
end
