class SystemPermissionSerializer < ActiveModel::Serializer
  has_one :user, serializer: UserPreviewSerializer
  has_one :auth_role, serializer: AuthRolePreviewSerializer
end
