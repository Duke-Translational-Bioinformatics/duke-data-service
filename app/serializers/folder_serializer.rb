class FolderSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :parent, :name, :project, :is_deleted

  def project
    { id: object.project_id }
  end

#TODO folder_id
  def parent
    { id: object.folder_id }
    # if object.folder_id
    #   { id: object.folder_id }
    # else
    #   "root"
    # end
  end

  def is_deleted
    object.is_deleted?
  end
end
