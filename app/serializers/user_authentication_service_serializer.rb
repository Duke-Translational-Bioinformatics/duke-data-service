class UserAuthenticationServiceSerializer < ActiveModel::Serializer
  self.root = false
  attributes :uid, :source

  def source
    object.authentication_service.name
  end
end
