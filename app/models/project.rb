class Project < ActiveRecord::Base
  after_initialize :init
  before_create :set_project_admin

  belongs_to :creator, class_name: "User"
  has_many :folders
  has_many :storage_folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  has_many :data_files

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true

  def init
    self.is_deleted = false if self.is_deleted.nil?
  end

  private
  def set_project_admin
    project_admin_role = AuthRole.where(text_id: 'project_admin').first
    if project_admin_role
      self.project_permissions.build(
        user: self.creator,
        auth_role: project_admin_role
      )
    end
  end
end
