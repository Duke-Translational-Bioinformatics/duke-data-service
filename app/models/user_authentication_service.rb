class UserAuthenticationService < ActiveRecord::Base
  belongs_to :user
  belongs_to :authentication_service

  validates :user_id, presence: true
  validates :authentication_service_id, presence: true
  validates :uid, presence: true,
                  uniqueness: { scope: :authentication_service_id,
                                message: 'your uid is not unique in the authentication service'
                              },
                  allow_blank: true
end
