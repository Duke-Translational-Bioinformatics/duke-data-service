class ProjectRole < ApplicationRecord
  self.primary_key = 'id'

  has_many :affiliations

  validates :id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
end
