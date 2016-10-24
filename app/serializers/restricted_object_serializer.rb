class RestrictedObjectSerializer < ActiveModel::Serializer
  attributes :kind, :id, :is_deleted

  def is_deleted
    object.is_deleted?
  end
end
