class SoftwareAgentSerializer < ActiveModel::Serializer
  attributes :id, :audit, :name, :description, :repo_url, :is_deleted
end
