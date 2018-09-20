require 'jwt'

class User < ActiveRecord::Base
  include Kinded
  include Graphed::Node

  default_scope { order('created_at DESC') }
  audited except: :last_login_at
  attr_accessor :current_software_agent, :current_user_authenticaiton_service

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
    source: :data_files
  has_many :file_versions, through: :created_files
  has_many :uploads,
    ->(user) { where(creator: user) },
    through: :file_versions
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

  def graph_model_name
    'Agent'
  end
end
