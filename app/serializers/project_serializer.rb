class ProjectSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :description, :is_deleted

  def id
    object.uuid
  end

  def is_deleted
    object.is_deleted?
  end
end
