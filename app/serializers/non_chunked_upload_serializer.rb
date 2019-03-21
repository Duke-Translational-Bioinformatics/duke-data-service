class NonChunkedUploadSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :name, :content_type, :size, :etag, :storage_container, :status, :audit

  attribute :signed_url, unless: :is_complete?

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :storage_provider, serializer: StorageProviderPreviewSerializer
  has_many :fingerprints, key: :hashes, serializer: FingerprintSerializer

  def status
    {
      initiated_on: object.created_at,
      completed_on: object.completed_at,
      is_consistent: object.is_consistent,
      purged_on: object.purged_on,
      error_on: object.error_at,
      error_message: object.error_message
    }
  end

  def is_complete?
    object.completed_at
  end
end
