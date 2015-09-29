class UserSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id,
             :username,
             :full_name,
             :first_name,
             :last_name,
             :email,
             :audit,
             :auth_provider,
             :last_login_at

  def full_name
    object.display_name
  end

  def auth_provider
    UserAuthenticationServiceSerializer.new(object.user_authentication_services.first)
  end
end
