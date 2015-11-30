class FolderSerializer < ActiveModel::Serializer
  attributes :kind, :id, :parent, :name, :project, :is_deleted, :audit, :ancestors

  has_one :project, serializer: ProjectPreviewSerializer

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
