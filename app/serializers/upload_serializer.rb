class UploadSerializer < ActiveModel::Serializer
  self.root = false
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

  def project
    {id: object.project_id}
  end

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

  def storage_provider
    {id: object.storage_provider_id, name: object.storage_provider.display_name}
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
