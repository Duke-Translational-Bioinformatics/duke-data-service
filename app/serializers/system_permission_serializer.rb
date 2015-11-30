class SystemPermissionSerializer < ActiveModel::Serializer
  attributes :user, :auth_role

  has_one :user, serializer: UserPreviewSerializer
  has_one :auth_role, serializer: AuthRolePreviewSerializer
end
