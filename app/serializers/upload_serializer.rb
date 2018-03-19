class UploadSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :name, :content_type, :size, :etag, :storage_container, :chunks, :status, :audit

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :storage_provider, serializer: StorageProviderPreviewSerializer
  has_many :chunks, serializer: ChunkPreviewSerializer
  has_many :fingerprints, key: :hashes, serializer: FingerprintSerializer

  def status
    {
      initiated_on: object.created_at,
      completed_on: object.completed_at,
      error_on: object.error_at,
      error_message: object.error_message
    }
  end
end
