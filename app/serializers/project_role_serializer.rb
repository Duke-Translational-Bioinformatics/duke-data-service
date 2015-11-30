class ProjectRoleSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :is_deprecated
end
