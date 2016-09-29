class FolderSearchDocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :is_deleted, :created_at, :updated_at, :label

  def is_deleted
    object.is_deleted?
  end
end
