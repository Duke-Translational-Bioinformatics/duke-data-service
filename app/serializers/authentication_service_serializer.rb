class AuthenticationServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :is_deprecated, :is_default, :login_initiation_url
end
