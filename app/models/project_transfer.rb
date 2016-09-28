class ProjectTransfer < ActiveRecord::Base
  include RequestAudited
  audited

  belongs_to :project
  belongs_to :from_user, class_name: 'User'

  has_many :project_transfer_users
  has_many :to_users, through: :project_transfer_users

  validates :project_id, presence: true
  validates :from_user_id, presence: true
end
