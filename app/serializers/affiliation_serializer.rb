class AffiliationSerializer < ActiveModel::Serializer
  attributes :user

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :project_role, serializer: ProjectRolePreviewSerializer

  def user
    {
      id: object.user_id,
      full_name: object.user.display_name,
      email: object.user.email
    }
  end
end
