class MembershipSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :project, :user, :project_roles

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

  def project_roles
    Array.new
  end
end
