class UserUsageSerializer < ActiveModel::Serializer
  self.root = false
  attributes :project_count, :file_count, :storage_bytes
end
