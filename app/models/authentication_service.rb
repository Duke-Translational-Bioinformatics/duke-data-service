class AuthenticationService < ActiveRecord::Base
  has_many :user_authentication_services

  validates :uuid, presence: true, uniqueness: true
  validates :name, presence: true
  validates :base_uri, presence: true

  def token_info(token)
    #TODO implement
  end
end
