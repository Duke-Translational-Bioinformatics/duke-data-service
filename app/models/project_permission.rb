class ProjectPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :auth_role

  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :auth_role_id, presence: true
end
