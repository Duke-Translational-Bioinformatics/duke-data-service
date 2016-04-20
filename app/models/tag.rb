class Tag < ActiveRecord::Base
  audited

  belongs_to :taggable, class_name: 'DataFile'
  has_many :project_permissions, through: :taggable

  validates :label, presence: true
  validates :taggable, presence: true

  after_initialize :set_taggable_type

  def set_taggable_type
    self.taggable_type ||= 'DataFile'
  end

end
