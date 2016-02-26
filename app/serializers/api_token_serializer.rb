class ApiTokenSerializer < ActiveModel::Serializer
  attributes :api_token, :expires_on
end
