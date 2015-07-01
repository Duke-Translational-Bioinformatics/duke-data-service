class Project < ActiveRecord::Base
  has_many :memberships
  has_many :storage_folders

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true
end
