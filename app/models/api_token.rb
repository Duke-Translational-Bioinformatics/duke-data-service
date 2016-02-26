class ApiToken
  def initialize(params = nil)
    unless params && params[:user]
      raise 'a User is required'
    end
    unless params[:user_authentication_service]
      raise 'Users current UserAuthenticationService is required'
    end
    @user = params[:user]
    @current_user_authentication_service = params[:user_authentication_service]
  end

  def api_token
    JWT.encode({
      'id' => @user.id,
      'service_id' => @current_user_authentication_service.authentication_service.service_id,
      'exp' => Time.now.to_i + 2.hours.to_i
    }, Rails.application.secrets.secret_key_base)
  end
end
