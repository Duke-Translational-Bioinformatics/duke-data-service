class UserSerializer < ActiveModel::Serializer
  self.root = false
  attributes :id, :full_name, :first_name, :last_name, :email, :auth_provider
  def full_name
    object.display_name
  end

  def auth_provider
    UserAuthenticationServiceSerializer.new(object.user_authentication_services.first)
  end
end
