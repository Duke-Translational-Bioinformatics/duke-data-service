class Tag < ActiveRecord::Base
  belongs_to :taggable, class_name: 'DataFile'
  has_many :project_permissions, through: :taggable


  validates :label, presence: true
  validates :taggable, presence: true

end
