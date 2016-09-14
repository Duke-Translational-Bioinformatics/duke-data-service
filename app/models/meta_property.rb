class MetaProperty < ActiveRecord::Base
  include RequestAudited
  audited
  belongs_to :meta_template
  belongs_to :property

  validates :property, presence: true,
    uniqueness: {scope: [:meta_template_id], case_sensitive: false}
  validates :meta_template, presence: true
  validates :value, presence: true
end
