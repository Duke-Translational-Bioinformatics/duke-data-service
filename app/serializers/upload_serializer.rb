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
      ready_for_chunks: object.ready_for_chunks?,
      completed_on: object.completed_at,
      is_consistent: object.is_consistent,
      purged_on: object.purged_on,
      error_on: object.error_at,
      error_message: object.error_message
    }
  end
end
