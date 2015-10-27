class StorageProviderSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :description, :is_deprecated

  def name
    object.display_name
  end

  def is_deprecated
    object.is_deprecated
  end
end
