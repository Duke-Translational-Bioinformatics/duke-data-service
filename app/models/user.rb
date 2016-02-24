require 'jwt'

class User < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include SerializedAudit
  audited except: :last_login_at

  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  has_many :project_permissions
  has_many :permitted_projects,
    -> { where(is_deleted: false) },
    class_name: 'Project',
    through: :project_permissions,
    source: :project
  has_many :created_files,
    -> { where(is_deleted: false) },
    class_name: 'DataFile',
    through: :permitted_projects,
    source: :data_files,
    foreign_key: "creator_id"
  has_many :uploads, through: :created_files
  has_many :affiliations
  has_one :system_permission
  has_one :api_key
  has_one :auth_role, through: :system_permission

  validates :username, presence: true, uniqueness: true

  def project_count
    self.permitted_projects.count
  end

  def file_count
    self.created_files.count
  end

  def storage_bytes
    self.uploads.sum(:size).to_i
  end

  def audited_user_info
    {
      id: id,
      username: username,
      full_name: display_name
    }
  end
end
