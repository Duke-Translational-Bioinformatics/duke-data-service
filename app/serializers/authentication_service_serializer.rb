class AuthenticationServiceSerializer < ActiveModel::Serializer
  attributes :id,
             :service_id,
             :name,
             :is_deprecated,
             :is_default,
             :login_initiation_url,
             :base_uri,
             :login_response_type
end
