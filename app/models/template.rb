class Template < ActiveRecord::Base
  include RequestAudited
  audited
  belongs_to :creator, class_name: 'User'
  has_many :properties

  validates :name, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[a-z0-9_]*\z/i}
  validates :label, presence: true
  validates :creator, presence: true
end
