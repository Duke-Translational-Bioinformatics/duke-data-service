class TagSerializer < ActiveModel::Serializer
  attributes :label

  has_one :taggable, serializer: TaggableSerializer, root: :object

end
