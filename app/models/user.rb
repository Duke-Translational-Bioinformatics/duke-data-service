require 'jwt'

class User < ActiveRecord::Base
  include SerializedAudit
  audited except: :last_login_at

  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  has_many :projects, foreign_key: "creator_id"
  has_many :data_files, foreign_key: "creator_id"
  has_many :uploads, through: :data_files
  has_many :affiliations
  has_one :system_permission
  has_one :auth_role, through: :system_permission

  validates :username, presence: true, uniqueness: true

  def project_count
    self.projects.count
  end

  def file_count
    self.data_files.count
  end

  def storage_bytes
    self.uploads.sum(:size)
  end

  def audited_user_info
    {
      id: id,
      username: username,
      full_name: display_name
    }
  end
end
