class ProjectPermission < ApplicationRecord
  include ProjectUpdater
  default_scope { order('created_at DESC') }
  audited

  belongs_to :user
  belongs_to :project
  belongs_to :auth_role
  has_many :project_permissions, through: :project

  validates :user_id, presence: true, uniqueness: {scope: :project_id, case_sensitive: false}
  validates :project_id, presence: true
  validates :auth_role_id, presence: true
end
