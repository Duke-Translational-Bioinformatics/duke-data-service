class Project < ActiveRecord::Base

  after_save :add_project_admin_role_to_user
  after_initialize :init

  belongs_to :creator, class_name: "User"
  has_many :memberships
  has_many :folders
  has_many :storage_folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true

  def init
    self.is_deleted = false if self.is_deleted.nil?
  end

  private
  def add_project_admin_role_to_user
    user = self.creator
    user.update(auth_role_ids: user.auth_roles=(['project_admin'])) if user
  end

end
