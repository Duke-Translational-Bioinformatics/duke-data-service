class ApiToken
  include ActiveModel::Model
  include ActiveModel::Serialization

  def initialize(params = nil)
    unless params && params[:user]
      raise 'a User is required'
    end
    @user = params[:user]

    if params[:user_authentication_service]
      @current_user_authentication_service = params[:user_authentication_service]
    elsif params[:software_agent]
      @current_software_agent = params[:software_agent]
    else
      raise 'UserAuthenticationService or SoftwareAgent is required'
    end
    @time_to_live = 2.hours.to_i
    @expires_on = Time.now.to_i
  end

  def api_token
    @time_to_live = 2.hours.to_i
    @expires_on = Time.now.to_i + 2.hours

    if @current_user_authentication_service
      JWT.encode({
        'id' => @user.id,
        'service_id' => @current_user_authentication_service.authentication_service.service_id,
        'exp' => @expires_on
      }, Rails.application.secrets.secret_key_base)
    else
      JWT.encode({
        'id' => @user.id,
        'software_agent_id' => @current_software_agent.id,
        'exp' => @expires_on
      }, Rails.application.secrets.secret_key_base)
    end
  end

  def expires_on
    @expires_on
  end

  def time_to_live
    @time_to_live
  end
end
