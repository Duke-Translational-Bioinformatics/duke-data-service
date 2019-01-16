class ProjectTransferUser < ApplicationRecord
  belongs_to :project_transfer
  belongs_to :to_user, class_name: 'User'

  validates :to_user, presence: true
  validates :project_transfer, presence: true
end
