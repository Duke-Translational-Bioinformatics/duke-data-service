class UploadPreviewSerializer < ActiveModel::Serializer
  attributes :id,
             :size,
             :hash

  has_one :storage_provider, serializer: StorageProviderPreviewSerializer

  def hash
    if object.fingerprint_value
      {
        value: object.fingerprint_value,
        algorithm: object.fingerprint_algorithm
      }
    else
      nil
    end
  end
end
