class Affiliation < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :project_role
  has_many :project_permissions, through: :project

  validates :user_id, presence: true, uniqueness: {scope: :project_id}
  validates :project_id, presence: true
  validates :project_role_id, presence: true
end
