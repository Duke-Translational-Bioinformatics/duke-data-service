class StorageProviderPreviewSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :description

  def name
    object.display_name
  end
end
