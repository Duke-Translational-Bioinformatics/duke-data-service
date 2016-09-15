class MetaPropertySerializer < ActiveModel::Serializer
  attributes :value
  has_one :property, serializer: PropertyPreviewSerializer, root: :template_property
end
