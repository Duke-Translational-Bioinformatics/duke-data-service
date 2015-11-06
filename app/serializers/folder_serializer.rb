class FolderSerializer < ActiveModel::Serializer
  self.root = false
  attributes :kind, :id, :parent, :name, :project, :is_deleted, :audit, :ancestors

  def project
    { id: object.project_id }
  end

  def parent
    parent = object.parent || object.project
    { kind: parent.kind, id: parent.id }
  end

  def is_deleted
    object.is_deleted?
  end

  def ancestors
    object.ancestors.collect do |a|
      {
        kind: a.kind,
        id: a.id,
        name: a.name
      }
    end
  end
end
