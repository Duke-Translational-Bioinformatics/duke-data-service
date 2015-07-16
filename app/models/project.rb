class Project < ActiveRecord::Base
  include StringIdCreator

  before_create :create_string_id  
  self.primary_key = 'id'
  has_many :memberships
  has_many :storage_folders

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true
end
