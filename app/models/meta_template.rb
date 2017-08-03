class MetaTemplate < ActiveRecord::Base
  include RequestAudited
  audited
  belongs_to :templatable, polymorphic: true
  belongs_to :template
  has_many :meta_properties, autosave: true, dependent: :destroy

  validates :template, presence: true,
    uniqueness: {scope: [:templatable_id], case_sensitive: false}
  validates :templatable, presence: true
  validates :template, presence: true

  validates_each :templatable do |record, attr, value|
    record.errors.add(attr, 'is not a templatable class') if value &&
      !templatable_classes.include?(value.class)
  end

  before_validation :lock_it_down

  def lock_it_down
    template.lock! if template
  end

  def project_permissions
    templatable.project_permissions
  end

  def self.templatable_classes
    [
      DataFile
    ]
  end
end
