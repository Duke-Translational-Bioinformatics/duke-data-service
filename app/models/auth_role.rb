class AuthRole < ActiveRecord::Base
  self.primary_key = 'id'
  validates :id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permissions, presence: true
  validates :contexts, presence: true

  scope :with_context, ->(context) { where('contexts @> ?', [context].to_json) }
end
