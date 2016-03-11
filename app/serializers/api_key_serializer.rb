class ApiKeySerializer < ActiveModel::Serializer
  attributes :key, :created_on

  def created_on
    object.created_at
  end
end
