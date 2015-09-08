class ProjectPermissionSerializer < ActiveModel::Serializer
  self.root = false
  attributes :project, :user, :auth_role

  def user
    {
      id: object.user.id,
      full_name: object.user.display_name
    }
  end

  def project
    { id: object.project.id }
  end

  def auth_role
    {
      id: object.auth_role.id,
      name: object.auth_role.name,
      description: object.auth_role.description
    }
  end
end
