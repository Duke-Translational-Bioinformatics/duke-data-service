class StorageProviderSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :is_deprecated, :chunk_hash_algorithm

  def name
    object.display_name
  end

  def is_deprecated
    object.is_deprecated
  end
end
