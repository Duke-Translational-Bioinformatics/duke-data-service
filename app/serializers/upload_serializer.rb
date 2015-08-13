class UploadSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :project, :name, :content_type, :size, :hash, :chunks, :storage_provider

  def project
    {id: object.project_id}
  end

  def hash
    {
      value: object.fingerprint_value,
      algorithm: object.fingerprint_algorithm
    }
  end

  def chunks
    []
  end

  def storage_provider
    {id: object.storage_provider_id}
  end
end
