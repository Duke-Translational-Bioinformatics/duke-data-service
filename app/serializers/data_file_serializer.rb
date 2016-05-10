class DataFileSerializer < ActiveModel::Serializer
  include AuditSummarySerializer
  attributes :kind, :id, :parent, :name, :audit, :is_deleted

  has_one :current_file_version, serializer: FileVersionPreviewSerializer, root: :current_version
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
