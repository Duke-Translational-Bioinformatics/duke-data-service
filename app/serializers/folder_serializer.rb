class FolderSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :parent, :name, :project, :is_deleted

  def project
    { id: object.project_id }
  end

  def parent
    { id: object.parent_id }
  end

  def is_deleted
    object.is_deleted?
  end
end
