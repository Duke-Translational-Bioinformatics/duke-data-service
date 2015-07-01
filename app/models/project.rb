class Project < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :creator_id, presence: true
end
