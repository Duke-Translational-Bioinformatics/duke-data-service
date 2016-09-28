class ProjectTransferUser < ActiveRecord::Base
  belongs_to :project_transfer
  belongs_to :to_user, class_name: 'User'

  validates :to_user_id, presence: true
  validates :project_transfer_id, presence: true
end
