class MetaTemplate < ActiveRecord::Base

  belongs_to :templatable, polymorphic: true
  belongs_to :template

  validates :template, presence: true,
    uniqueness: {scope: [:templatable_id, :templatable_type], case_sensitive: false}
  validates :templatable, presence: true
  validates :template, presence: true

  validates_each :templatable do |record, attr, value|
    record.errors.add(attr, 'is not a templatable class') if value &&
      !templatable_classes.include?(value.class)
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
