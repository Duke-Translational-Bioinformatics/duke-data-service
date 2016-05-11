class Tag < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  audited

  belongs_to :taggable, polymorphic: true

  validates :label, presence: true
  validates :taggable, presence: true
end
