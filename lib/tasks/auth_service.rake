namespace :authentication_service do
  desc "creates an authentication_service using ENV[UUID, BASE_URI, NAME]"
  task create: :environment do
    unless AuthenticationService.where(uuid: ENV['UUID']).exists?
      AuthenticationService.create(
        uuid: ENV['UUID'],
        base_uri: ENV['BASE_URI'],
        name: ENV['NAME']
      )
    end
  end

  desc "destroys the authentication_service defined in ENV[UUID]"
  task destroy: :environment do
    auths = AuthenticationService.where(uuid: ENV['UUID']).first
    if auths
      auths.destroy
    end
  end
end
