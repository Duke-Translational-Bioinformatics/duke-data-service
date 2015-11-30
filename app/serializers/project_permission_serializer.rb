class ProjectPermissionSerializer < ActiveModel::Serializer
  attributes :project, :user, :auth_role

  has_one :project, serializer: ProjectPreviewSerializer
  has_one :user, serializer: UserPreviewSerializer
  has_one :auth_role, serializer: AuthRolePreviewSerializer
end
