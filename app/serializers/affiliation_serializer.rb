class AffiliationSerializer < ActiveModel::Serializer
  attributes :project, :user, :project_role

  def project
    {id: object.project_id}
  end

  def user
    {
      id: object.user_id,
      full_name: object.user.display_name,
      email: object.user.email
    }
  end

  def project_role
    {
      id: object.project_role.id,
      name: object.project_role.name
    }
  end
end
