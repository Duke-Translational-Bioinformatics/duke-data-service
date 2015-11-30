class SystemPermissionSerializer < ActiveModel::Serializer
  attributes :user, :auth_role

  def user
    {
      id: object.user.id,
      username: object.user.username,
      full_name: object.user.display_name
    }
  end

  def auth_role
    {
      id: object.auth_role.id,
      name: object.auth_role.name,
      description: object.auth_role.description
    }
  end
end
