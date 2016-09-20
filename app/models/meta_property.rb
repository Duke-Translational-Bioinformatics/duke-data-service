class MetaProperty < ActiveRecord::Base
  include RequestAudited
  attr_accessor :key

  audited
  belongs_to :meta_template, touch: true
  belongs_to :property

  before_validation :set_property_from_key

  validates :property, presence: true,
    uniqueness: {scope: [:meta_template_id], case_sensitive: false}
  validates :meta_template, presence: true
  validates :value, presence: true

  validates_each :key do |record, attr, value|
    record.errors.add(attr, 'key is not in the template') if value && !record.property
  end

  def set_property_from_key
    if key
      self.property = nil
      if meta_template && meta_template.template
        self.property = meta_template.template.properties.where(key: key).first
      end
    end
  end
end
