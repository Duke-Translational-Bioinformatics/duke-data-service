class ProjectTransfer < ActiveRecord::Base
  audited

  belongs_to :project
  belongs_to :from_user, class_name: 'User'

  has_many :project_permissions, through: :project
  has_many :project_transfer_users
  has_many :to_users, through: :project_transfer_users

  validates :project, presence: true
  validates :status, uniqueness: {
      scope: [:project_id],
      message: 'Pending transfer already exists'
    }, if: :pending?
  validates_each :status, on: :update, unless: :status_was_pending? do |record, attr, value|
    record.errors.add(attr, 'cannot be changed when not pending')
  end
  validates :status_comment, immutable: true, unless: :status_was_pending?
  validates :from_user, presence: true
  validates :project_transfer_users, presence: true

  enum status: [:pending, :rejected, :accepted, :canceled]

  #callbacks
  before_validation :reassign_permissions

  def status_was_pending?
    status_was == 'pending'
  end

  def reassign_permissions
    if accepted?
      project.project_permissions.destroy_all
      project_viewer = AuthRole.find("project_viewer")
      project_admin = AuthRole.find("project_admin")
      project.project_permissions.build(user: from_user, auth_role: project_viewer)
      to_users.each do |to_user|
        project.project_permissions.build(user: to_user, auth_role: project_admin)
      end
      project.save
    end
  end

end
