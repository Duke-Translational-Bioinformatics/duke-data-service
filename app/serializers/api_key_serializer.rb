class ApiKeySerializer < ActiveModel::Serializer
  attributes :key, :created_at
end
