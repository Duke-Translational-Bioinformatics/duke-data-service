class AuthenticationServiceSerializer < ActiveModel::Serializer
  attributes :id, :service_id, :name, :is_deprecated, :is_default, :login_initiation_url
end
