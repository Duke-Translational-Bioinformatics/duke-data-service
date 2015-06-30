class PermissionSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :description

  def id
    object.title
  end

end
