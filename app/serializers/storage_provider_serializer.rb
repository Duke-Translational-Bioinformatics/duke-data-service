class StorageProviderSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :is_deprecated, :is_default, :chunk_hash_algorithm,
  :chunk_max_number, :chunk_max_size_bytes

  def name
    object.display_name
  end

  def is_deprecated
    object.is_deprecated
  end
end
