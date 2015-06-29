class Permission < ActiveRecord::Base
  belongs_to :auth_role

  validates :title, presence: true
  validates :description, presence: true
end
