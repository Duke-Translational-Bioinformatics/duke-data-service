class IdentityProvider < ActiveRecord::Base
  validates :host, presence: true
  validates :port, presence: true
end
