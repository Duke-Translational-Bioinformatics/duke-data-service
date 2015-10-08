class ProjectSerializer < ActiveModel::Serializer
  self.root = false
  attributes :kind, :id, :name, :description, :is_deleted, :audit

  def is_deleted
    object.is_deleted?
  end
end
