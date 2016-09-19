class MetaTemplateSerializer < ActiveModel::Serializer
  has_one :templatable, serializer: TemplatableSerializer, root: :object
  has_one :template, serializer: TemplatePreviewSerializer
  has_many :meta_properties, serializer: MetaPropertySerializer, root: :properties
end
