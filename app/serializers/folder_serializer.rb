class FolderSerializer < ActiveModel::Serializer
  self.root = false
  attributes :kind, :id, :parent, :name, :project, :is_deleted, :audit

  def project
    { id: object.project_id }
  end

  def parent
    parent = object.parent || object.project
    { kind: parent.kind, id: parent.id }
    # if object.parent_id
    #   { id: object.parent_id }
    # else
    #   "root"
    # end
  end

  def is_deleted
    object.is_deleted?
  end
end
