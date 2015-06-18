require 'jwt'

class User < ActiveRecord::Base
  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services
end
