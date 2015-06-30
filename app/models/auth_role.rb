class AuthRole < ActiveRecord::Base
  validates :text_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permissions, presence: true
  validates :contexts, presence: true
end
