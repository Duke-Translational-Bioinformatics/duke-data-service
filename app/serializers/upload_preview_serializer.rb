class UploadPreviewSerializer < ActiveModel::Serializer
  attributes :id, :size

  has_one :storage_provider, serializer: StorageProviderPreviewSerializer
  has_many :fingerprints, root: :hashes, serializer: FingerprintSerializer
end
