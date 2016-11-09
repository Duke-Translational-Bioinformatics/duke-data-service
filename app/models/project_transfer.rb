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
  validates :status, immutable: true, unless: :status_was_pending?
  validates :from_user, presence: true
  validates :project_transfer_users, presence: true

  def pending?
    status && status.downcase == 'pending'
  end

  def rejected?
    status && status.downcase == 'rejected'
  end

  def accepted?
    status && status.downcase == 'accepted'
  end

  def canceled?
    status && status.downcase == 'canceled'
  end

  def status_was_pending?
    status_was && status_was.downcase == 'pending'
  end

end
