class ApiTokenSerializer < ActiveModel::Serializer
  attributes :api_token, :expires_on, :time_to_live
end
