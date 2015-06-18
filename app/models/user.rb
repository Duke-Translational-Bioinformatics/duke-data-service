require 'jwt'

class User < ActiveRecord::Base
  has_many :user_authentication_services
  accepts_nested_attributes_for :user_authentication_services

  def api_token(authentication_service)
    JWT.encode({
      'id' => id,
      'uuid' => uuid,
      'authentication_service_id' => authentication_service.id,
      'exp' => Time.now.to_i + 2.hours.to_i
    }, Rails.application.secrets.secret_key_base)
  end
end
