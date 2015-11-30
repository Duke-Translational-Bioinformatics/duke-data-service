class UploadSerializer < ActiveModel::Serializer
  attributes :id,
             :project,
             :name,
             :content_type,
             :size,
             :etag,
             :hash,
             :chunks,
             :storage_provider,
             :status,
             :audit

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :storage_provider, serializer: StorageProviderPreviewSerializer

  def hash
    {
      value: object.fingerprint_value,
      algorithm: object.fingerprint_algorithm,
      client_reported: true,
      confirmed: false
    }
  end

  def chunks
    object.chunks.collect{ |chunk|
      {
        number: chunk.number,
        size: chunk.size,
        hash: { value: chunk.fingerprint_value, algorithm: chunk.fingerprint_algorithm }
      }
    }
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
