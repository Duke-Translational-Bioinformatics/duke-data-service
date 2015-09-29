require 'jwt'

class User < ActiveRecord::Base
  audited except: :last_login_at

  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  has_many :projects, foreign_key: "creator_id"
  has_many :data_files, foreign_key: "creator_id"
  has_many :uploads, through: :data_files
  has_many :affiliations
  has_one :system_permission

  validates :username, presence: true, uniqueness: true
  validates_each :auth_role_ids do |record, attr, value|
    record.errors.add(attr, 'does not exist') if value &&
      !value.empty? &&
      value.count > AuthRole.where(id: value).count
  end

  def auth_roles
    (auth_role_ids || []).collect do |role_id|
      AuthRole.where(id: role_id).first
    end
  end

  def auth_roles=(new_auth_role_ids)
    self.auth_role_ids = new_auth_role_ids
  end

  def project_count
    self.projects.count
  end

  def file_count
    self.data_files.count
  end

  def storage_bytes
    self.uploads.sum(:size)
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

  def audited_user_info
    {
      id: id,
      username: username,
      full_name: display_name
    }
  end
end
