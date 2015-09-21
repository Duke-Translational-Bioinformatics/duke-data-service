class SystemPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :auth_role

  validates :user_id, presence: true, uniqueness: true
  validates :auth_role_id, presence: true
end
