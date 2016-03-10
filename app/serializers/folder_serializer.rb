class FolderSerializer < ActiveModel::Serializer
  attributes :kind, :id, :parent, :name, :is_deleted, :audit

  has_one :project, serializer: ProjectPreviewSerializer
  has_many :ancestors, serializer: AncestorSerializer

  def parent
    parent = object.parent || object.project
    { kind: parent.kind, id: parent.id }
  end

  def is_deleted
    object.is_deleted?
  end
end
