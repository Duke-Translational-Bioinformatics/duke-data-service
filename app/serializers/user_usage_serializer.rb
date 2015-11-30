class UserUsageSerializer < ActiveModel::Serializer
  attributes :project_count, :file_count, :storage_bytes
end
