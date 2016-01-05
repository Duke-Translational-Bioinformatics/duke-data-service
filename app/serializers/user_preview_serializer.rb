class UserPreviewSerializer < ActiveModel::Serializer
  attributes :id,
             :username,
             :full_name

  def full_name
    object.display_name
  end
end
