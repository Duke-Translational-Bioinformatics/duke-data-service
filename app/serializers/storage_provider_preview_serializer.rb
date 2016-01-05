class StorageProviderPreviewSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  def name
    object.display_name
  end
end
