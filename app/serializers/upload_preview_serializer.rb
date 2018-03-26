class UploadPreviewSerializer < ActiveModel::Serializer
  attributes :id, :size

  has_one :storage_provider, serializer: StorageProviderPreviewSerializer
  has_many :fingerprints, key: :hashes, serializer: FingerprintSerializer
end
