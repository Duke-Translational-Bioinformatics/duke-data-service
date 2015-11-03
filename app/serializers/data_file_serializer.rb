class DataFileSerializer < ActiveModel::Serializer
  self.root = false
  attributes :kind, :id, :parent, :name, :project, :audit, :upload, :virtual_path, :is_deleted

  def project
    { id: object.project_id }
  end

  def parent
    parent = object.parent || object.project
    { kind: parent.kind, id: parent.id }
  end

  def upload
    { id: object.upload_id }
  end

  def is_deleted
    object.is_deleted?
  end
end
