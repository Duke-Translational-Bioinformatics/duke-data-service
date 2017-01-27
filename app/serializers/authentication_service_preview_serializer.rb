class AuthenticationServicePreviewSerializer < ActiveModel::Serializer
  attributes :id, :name, :is_affiliate_search_supported

  def is_affiliate_search_supported
    object.identity_provider ? true : false
  end
end
