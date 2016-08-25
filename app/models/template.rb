class Template < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'

  validates :name, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[a-z0-9_]*\z/i}
  validates :label, presence: true
  validates :creator, presence: true
end
