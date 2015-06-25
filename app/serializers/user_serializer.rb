class UserSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :email

  def id
    object.uuid
  end
end
