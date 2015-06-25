class AuthRoleSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :description, :permissions, :contexts, :is_deprecated

  def id
    object.text_id
  end
end
