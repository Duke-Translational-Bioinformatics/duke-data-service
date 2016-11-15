def is_default
  is_default = (ENV['AUTH_SERVICE_IS_DEFAULT'] && ENV['AUTH_SERVICE_IS_DEFAULT'].downcase != "false") ? true : false
  if is_default
    default_service = AuthenticationService.where(is_default: true).take
    if default_service
      raise "#{default_service.inspect} is already the default authentication_service"
    end
  end
  is_default
end

namespace :auth_service do
  desc "transfer default authentication_service from ENV[FROM_AUTH_SERVICE_ID] to ENV[TO_AUTH_SERVICE_ID]"
  task transfer_default: :environment do
    raise 'please set ENV[FROM_AUTH_SERVICE_ID] and ENV[TO_AUTH_SERVICE_ID]' unless ENV['FROM_AUTH_SERVICE_ID'] && ENV['TO_AUTH_SERVICE_ID']
    from_auth_service = AuthenticationService.find_by!(service_id: ENV['FROM_AUTH_SERVICE_ID'])
    raise '#{from_auth_service.service_id} is not default' unless from_auth_service.is_default?

    to_auth_service = AuthenticationService.find_by!(service_id: ENV['TO_AUTH_SERVICE_ID'])

    from_auth_service.transaction do
      from_auth_service.update!(is_default: false)
      to_auth_service.update!(is_default: true)
    end
  end

  desc "set default authentication_service using ENV[AUTH_SERVICE_SERVICE_ID]"
  task set_default: :environment do
    raise 'AUTH_SERVICE_SERVICE_ID environment variable is required' unless ENV['AUTH_SERVICE_SERVICE_ID']
    begin
      auth_service = AuthenticationService.find_by!(service_id: ENV['AUTH_SERVICE_SERVICE_ID'])
    rescue
      raise "AUTH_SERVICE_SERVICE_ID is not a registered service"
    end

    if auth_service.is_default?
      $stderr.puts "AUTH_SERVICE_SERVICE_ID service is already default"
    else
      existing_default_auth_service = AuthenticationService.find_by(is_default: true)
      if existing_default_auth_service
        raise "Service #{existing_default_auth_service.service_id} is already default. Use auth_service_transfer_default instead"
      end
      auth_service.update!(is_default: true)
    end
  end

  namespace :duke do
    desc "creates a duke_authentication_service using
      ENV[AUTH_SERVICE_SERVICE_ID]
      ENV[AUTH_SERVICE_BASE_URI]
      ENV[AUTH_SERVICE_NAME]
      ENV[AUTH_SERVICE_IS_DEFAULT]
    this will fail if AUTH_SERVICE_IS_DEFAULT is true and there is already a default authentication_service\n"
    task create: :environment do
      service_id = ENV['AUTH_SERVICE_SERVICE_ID'] || SecureRandom.uuid
      unless DukeAuthenticationService.where(service_id: service_id).exists?
        DukeAuthenticationService.create!(
          service_id: service_id,
          base_uri: ENV['AUTH_SERVICE_BASE_URI'],
          name: ENV['AUTH_SERVICE_NAME'],
          is_default: is_default
        )
      end
    end

    desc "destroys the duke_authentication_service defined in ENV[AUTH_SERVICE_SERVICE_ID], warns if there is not a default authentication_service"
    task destroy: :environment do
      auths = DukeAuthenticationService.where(service_id: ENV['AUTH_SERVICE_SERVICE_ID']).first
      if auths
        $stderr.puts "WARNING: destroying default authentication_service" if auths.is_default?
        auths.destroy
      end
    end
  end

  namespace :openid do
    desc "creates a openid_authentication_service using
      ENV[AUTH_SERVICE_SERVICE_ID]
      ENV[AUTH_SERVICE_BASE_URI]
      ENV[AUTH_SERVICE_NAME]
      ENV[AUTH_SERVICE_IS_DEFAULT]
      ENV[AUTH_SERVICE_CLIENT_ID]
      ENV[AUTH_SERVICE_CLIENT_SECRET]
    this will fail if AUTH_SERVICE_IS_DEFAULT is true and there is already a default authentication_service\n"
    task create: :environment do
      service_id = ENV['AUTH_SERVICE_SERVICE_ID'] || SecureRandom.uuid
      unless OpenidAuthenticationService.where(service_id: service_id).exists?
        OpenidAuthenticationService.create!(
          service_id: service_id,
          base_uri: ENV['AUTH_SERVICE_BASE_URI'],
          name: ENV['AUTH_SERVICE_NAME'],
          client_id: ENV['AUTH_SERVICE_CLIENT_ID'],
          client_secret: ENV['AUTH_SERVICE_CLIENT_SECRET'],
          is_default: is_default
        )
      end
    end

    desc "destroys the openid_authentication_service defined in ENV[AUTH_SERVICE_SERVICE_ID], warns if there is not a default authentication_service"
    task destroy: :environment do
      auths = OpenidAuthenticationService.where(service_id: ENV['AUTH_SERVICE_SERVICE_ID']).first
      if auths
        $stderr.puts "WARNING: destroying default authentication_service" if auths.is_default?
        auths.destroy
      end
    end
  end
end
