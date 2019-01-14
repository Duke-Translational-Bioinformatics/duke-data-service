class ProjectStorageProvider < ApplicationRecord
  belongs_to :project
  belongs_to :storage_provider

  validates :project, presence: true
  validates :storage_provider, presence: true
  validates :storage_provider_id, uniqueness: {scope: :project_id}

  after_create :initialize_storage

  def initialize_storage
    ProjectStorageProviderInitializationJob.perform_later(
      job_transaction: ProjectStorageProviderInitializationJob.initialize_job(project),
      project_storage_provider: self
    )
  end
end
