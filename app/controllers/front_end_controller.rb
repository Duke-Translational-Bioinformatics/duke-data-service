class FrontEndController < ApplicationController
  def index
    @location_path = "#{params[:path]}"
    @auth_service = AuthenticationService.first
  end
end
