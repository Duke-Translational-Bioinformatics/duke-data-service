class ProjectPermissionSerializer < ActiveModel::Serializer
  self.root = false
  attributes :project, :user, :auth_roles

  def user
    {
      id: object.user.uuid,
      full_name: object.user.display_name
    }
  end

  def project
    { id: object.project.uuid }
  end
end
