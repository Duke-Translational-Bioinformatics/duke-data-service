class AffiliateSerializer < ActiveModel::Serializer
  attributes :uid,
             :full_name,
             :first_name,
             :last_name,
             :email

  def uid
    object.username
  end

  def full_name
    object.display_name
  end
end
