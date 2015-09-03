class DataFileSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :parent, :name, :project, :upload, :virtual_path, :is_deleted

  def project
    { id: object.project_id }
  end

  def parent
    { id: object.parent_id }
  end

  def upload
    { id: object.upload_id }
  end

  def is_deleted
    object.is_deleted?
  end

  def virtual_path
    object.virtual_path
  end
end
