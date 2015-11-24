namespace :authentication_service do
  desc "creates an authentication_service using ENV[AUTH_SERVICE_ID, BASE_URI, NAME]"
  task create: :environment do
    unless AuthenticationService.where(service_id: ENV['AUTH_SERVICE_ID']).exists?
      AuthenticationService.create(
        service_id: ENV['AUTH_SERVICE_ID'],
        base_uri: ENV['BASE_URI'],
        name: ENV['NAME']
      )
    end
  end

  desc "destroys the authentication_service defined in ENV[AUTH_SERVICE_ID]"
  task destroy: :environment do
    auths = AuthenticationService.where(service_id: ENV['AUTH_SERVICE_ID']).first
    if auths
      auths.destroy
    end
  end
end
