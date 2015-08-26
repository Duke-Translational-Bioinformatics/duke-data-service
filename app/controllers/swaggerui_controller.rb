class SwaggeruiController < ApplicationController
  def index
    @auth_service = AuthenticationService.first
    @state = SecureRandom.hex
  end
end
