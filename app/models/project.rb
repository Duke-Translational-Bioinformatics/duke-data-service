class Project < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  include Kinded
  include ChildMinder
  include RequestAudited
  include JobTransactionable
  include UnRestorable
  audited

  belongs_to :creator, class_name: "User"
  has_many :folders
  has_many :project_permissions
  has_many :uploads
  has_many :affiliations
  has_many :data_files
  has_many :children, -> { where parent_id: nil }, class_name: "Container", autosave: true
  has_many :containers

  validates :name, presence: true, unless: :is_deleted
  validates :description, presence: true, unless: :is_deleted
  validates :creator_id, presence: true, unless: :is_deleted
  validates :is_deleted, immutable: true, if: :is_deleted_was

  after_create :set_project_admin
  after_create :initialize_storage

  def set_project_admin
    project_admin_role = AuthRole.where(id: 'project_admin').first
    if project_admin_role
      last_audit = self.audits.last
      pp = self.project_permissions.create(
        user: self.creator,
        auth_role: project_admin_role,
        audit_comment: last_audit.comment
      )
      pp
    end
  end

  def initialize_storage
    storage_provider = StorageProvider.first
    ProjectStorageProviderInitializationJob.perform_later(
      job_transaction: ProjectStorageProviderInitializationJob.initialize_job(self),
      storage_provider: storage_provider,
      project: self
    )
  end
end
