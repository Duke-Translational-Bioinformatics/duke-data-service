class ProjectTransfer < ActiveRecord::Base
  include RequestAudited
  audited

  belongs_to :project
  belongs_to :from_user, class_name: 'User'

  has_many :project_permissions, through: :project
  has_many :project_transfer_users
  has_many :to_users, through: :project_transfer_users

  validates :project, presence: true
  validates :status, uniqueness: {
      scope: [:project_id],
      case_sensitive: false,
      message: 'Pending transfer already exists'
    }, if: :pending?
  validates :from_user, presence: true
  validates :project_transfer_users, presence: true

  private

  def pending?
    status && status.downcase == 'pending'
  end

end
