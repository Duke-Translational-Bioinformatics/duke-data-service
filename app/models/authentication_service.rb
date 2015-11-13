class AuthenticationService < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  has_many :user_authentication_services

  validates :name, presence: true
  validates :base_uri, presence: true
end
