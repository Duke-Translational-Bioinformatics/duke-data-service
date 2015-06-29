class AuthRole < ActiveRecord::Base
  belongs_to :user
  has_many :permissions

  validates :text_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permissions, presence: true
  validates :contexts, presence: true
end
