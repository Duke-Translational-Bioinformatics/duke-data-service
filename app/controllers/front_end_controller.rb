class FrontEndController < ApplicationController
  def index
    @auth_service = AuthenticationService.first
  end
end
