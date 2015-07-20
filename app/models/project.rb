class Project < ActiveRecord::Base
  include StringIdCreator
  self.primary_key = 'id'

  before_create :create_string_id  
  after_initialize :init

  has_many :memberships
  has_many :storage_folders
  has_many :project_permissions

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true

  def init
    self.is_deleted = false if self.is_deleted.nil?
  end
end
