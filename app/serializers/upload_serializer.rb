class UploadSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :id, :name, :content_type, :size, :etag, :hash, :chunks, :status, :audit

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :storage_provider, serializer: StorageProviderPreviewSerializer
  has_many :chunks, serializer: ChunkPreviewSerializer

  def hash
    if object.fingerprint_value
      {
        value: object.fingerprint_value,
        algorithm: object.fingerprint_algorithm,
        client_reported: true,
        confirmed: false
      }
    else
      nil
    end
  end

  def status
    {
      initiated_on: object.created_at,
      completed_on: object.completed_at,
      error_on: object.error_at,
      error_message: object.error_message
    }
  end
end
