class ProjectRoleSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :name, :description, :is_deprecated
end
