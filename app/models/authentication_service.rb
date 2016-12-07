class AuthenticationService < ActiveRecord::Base
  has_many :user_authentication_services

  validates :service_id, presence: true
  validates :name, presence: true
  validates :base_uri, presence: true
  validates :client_id, presence: true
  validates :login_initiation_uri, presence: true
  validates :login_response_type, presence: true
  validates :is_default, uniqueness: true, if: :is_default

  def login_initiation_url
    [
      base_uri,
      login_initiation_uri
    ].join('/') + '?' + [
      "response_type=#{login_response_type}",
      "client_id=#{client_id}"
    ].join('&')
  end
end
