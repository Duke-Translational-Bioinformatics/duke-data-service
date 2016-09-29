class Template < ActiveRecord::Base
  include RequestAudited
  audited
  belongs_to :creator, class_name: 'User'
  has_many :properties
  has_many :meta_templates

  validates :name, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[a-z0-9_]*\z/i},
    length: {maximum: 60}
  validates :name, immutable: true, if: :has_meta_templates?
  validates :label, presence: true
  validates :creator, presence: true

  private

  def has_meta_templates?
    meta_templates.exists?
  end
end
