class UserApiSecret < ActiveRecord::Base
  audited

  belongs_to :user
  validates :user_id, presence: true
  validates :key, presence: true
end
