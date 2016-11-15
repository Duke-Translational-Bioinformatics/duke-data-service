class OpenidAuthenticationService < AuthenticationService
  validates :client_id, presence: true
  validates :client_secret, presence: true

  def get_user_for_access_token(token)
    raise InvalidAccessTokenException.new if token.nil?
    user_info = get_userinfo(token)
    uid = user_info['dukeNetID']
    user_authentication_service = user_authentication_services.find_by(uid: uid)
    if user_authentication_service
      user = user_authentication_service.user
      user.current_user_authenticaiton_service = user_authentication_service
      user
    else
      user = User.where(username: uid).take
      unless user
        user = User.new(
          id: SecureRandom.uuid,
          username: uid,
          etag: SecureRandom.hex,
          email: user_info['email'],
          display_name: user_info['name'],
          first_name: user_info['given_name'],
          last_name: user_info['family_name']
        )
      end
      user_authentication_service = user.user_authentication_services.build(
        uid: uid,
        authentication_service: self
      )
      user.current_user_authenticaiton_service = user_authentication_service
      user
    end
  end

  def get_userinfo(token)
    resp = HTTParty.post("#{base_uri}/userinfo",
      body: "access_token=#{token}"
    )
    raise InvalidAccessTokenException.new unless resp.response.code.to_i == 200
    JSON.parse(resp.body)
  end
end
