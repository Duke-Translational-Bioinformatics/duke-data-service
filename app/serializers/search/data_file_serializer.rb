class Search::DataFileSerializer < DataFileSerializer
  attributes :kind, :id, :parent, :name, :audit, :is_deleted,
             :created_at,
             :updated_at,
             :label,
             :meta

  has_many :tags, serializer: Search::TagSummarySerializer
  has_one :creator, serializer: Search::UserSummarySerializer

  def meta
    object.meta_templates.each_with_object({}) do |meta_template, metadata|
      metadata[meta_template.template.name] = {}
      meta_template.meta_properties.each_with_object(metadata[meta_template.template.name]) do |prop, meta_prop|
        meta_prop[prop.property.key] = prop.value
      end
    end
  end
end
