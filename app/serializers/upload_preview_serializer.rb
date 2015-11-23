class UploadPreviewSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id,
             :size,
             :hash

  has_one :storage_provider, serializer: StorageProviderPreviewSerializer

  def hash
    {
      value: object.fingerprint_value,
      algorithm: object.fingerprint_algorithm
    }
  end
end
