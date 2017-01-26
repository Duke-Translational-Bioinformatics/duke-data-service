class AffiliateSerializer < ActiveModel::Serializer
  attributes :uid,
             :full_name,
             :first_name,
             :last_name,
             :email,
             :auth_provider

  def uid
    object.username
  end
  
  def full_name
    object.display_name
  end

  def auth_provider
    AuthenticationServicePreviewSerializer.new(object.user_authentication_services.first.authentication_service)
  end
end
