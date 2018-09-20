class Tag < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  audited

  belongs_to :taggable, polymorphic: true, touch: true

  validates :label, presence: true,
    uniqueness: {scope: [:taggable_id, :taggable_type], case_sensitive: false}
  validates :taggable, presence: true

  validates_each :taggable do |record, attr, value|
    record.errors.add(attr, 'is not a taggable class') if value &&
      !taggable_classes.include?(value.class)
  end

  def project_permissions
    taggable.project_permissions
  end

  def self.taggable_classes
    [
      Activity,
      DataFile
    ]
  end

  def self.label_like(label_contains)
    where("label LIKE ?", "%#{label_contains}%")
  end

  def self.label_group
    unscope(:order).select(:label).group(:label)
  end

  def self.tag_labels
    maxes = label_group.maximum(:created_at)
    counts = label_group.count
    counts.keys.collect do |l|
      TagLabel.new(label: l, count: counts[l], last_used_on: maxes[l])
    end
  end
end
