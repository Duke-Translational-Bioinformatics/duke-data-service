class AuthenticationServicePreviewSerializer < ActiveModel::Serializer
  attributes :id, :name, :affilate_search_supported

  def affiliate_search_supported
    object.identity_provider ? true : false
  end
end
