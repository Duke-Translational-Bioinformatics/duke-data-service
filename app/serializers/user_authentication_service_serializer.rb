class UserAuthenticationServiceSerializer < ActiveModel::Serializer
  attributes :uid, :source

  def source
    object.authentication_service.name
  end
end
