class Tag < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  audited

  belongs_to :taggable, class_name: 'DataFile'
  has_many :project_permissions, through: :taggable

  validates :label, presence: true
  validates :taggable, presence: true

  after_initialize :set_taggable_type

  def set_taggable_type
    self.taggable_type ||= 'DataFile'
  end

  def self.label_like(label_contains) 
    where("label LIKE ?", "%#{label_contains}%")
  end

  def self.label_count
    unscope(:order).select(:label).group(:label).count.collect do |l|
      TagLabel.new(label: l.first, count: l.second)
    end
  end
end
