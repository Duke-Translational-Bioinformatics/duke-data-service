require 'jwt'

class User < ActiveRecord::Base
  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  def auth_roles
    auth_role_ids
  end

  def auth_roles=(new_auth_role_ids)
    self.auth_role_ids = new_auth_role_ids
  end
end
