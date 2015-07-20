class UserSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :full_name, :first_name, :last_name, :email
  def full_name
    object.display_name
  end
end
