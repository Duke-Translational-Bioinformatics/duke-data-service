class Tag < ActiveRecord::Base
  belongs_to :taggable, polymorphic: true

  validates :label, presence: true
  validates :taggable, presence: true



end
