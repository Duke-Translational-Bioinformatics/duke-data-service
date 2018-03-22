class MetaPropertySerializer < ActiveModel::Serializer
  attributes :value
  has_one :property, serializer: PropertyPreviewSerializer, key: :template_property
end
