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
    raise "#{from_auth_service.service_id} is not default" unless from_auth_service.is_default?

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

  desc "deprecate authentication_service using ENV[AUTH_SERVICE_SERVICE_ID]"
  task deprecate: :environment do
    raise 'AUTH_SERVICE_SERVICE_ID environment variable is required' unless ENV['AUTH_SERVICE_SERVICE_ID']
    begin
      auth_service = AuthenticationService.find_by!(service_id: ENV['AUTH_SERVICE_SERVICE_ID'])
    rescue
      raise "AUTH_SERVICE_SERVICE_ID is not a registered service"
    end

    if auth_service.is_deprecated?
      $stderr.puts "AUTH_SERVICE_SERVICE_ID service is already deprecated"
    else
      auth_service.update!(is_deprecated: true)
    end
  end

  desc "destroys the authentication_service defined in ENV[AUTH_SERVICE_SERVICE_ID], warns if specified authentication_service is the default"
  task destroy: :environment do
    auths = AuthenticationService.find_by(service_id: ENV['AUTH_SERVICE_SERVICE_ID'])
    if auths
      $stderr.puts "WARNING: destroying default authentication_service" if auths.is_default?
      auths.destroy
    end
  end

  namespace :duke do
    desc "creates a duke_authentication_service using
      ENV[AUTH_SERVICE_SERVICE_ID]
      ENV[AUTH_SERVICE_BASE_URI]
      ENV[AUTH_SERVICE_NAME]
      ENV[AUTH_SERVICE_IS_DEFAULT]
      ENV[AUTH_SERVICE_LOGIN_INITIATION_URI]
      ENV[AUTH_SERVICE_LOGIN_RESPONSE_TYPE]
      ENV[AUTH_SERVICE_CLIENT_ID]
    this will fail if AUTH_SERVICE_IS_DEFAULT is true and there is already a default authentication_service\n"
    task create: :environment do
      service_id = ENV['AUTH_SERVICE_SERVICE_ID'] || SecureRandom.uuid
      unless DukeAuthenticationService.where(service_id: service_id).exists?
        DukeAuthenticationService.create!(
          service_id: service_id,
          base_uri: ENV['AUTH_SERVICE_BASE_URI'],
          name: ENV['AUTH_SERVICE_NAME'],
          is_default: is_default,
          client_id: ENV['AUTH_SERVICE_CLIENT_ID'],
          login_initiation_uri: ENV['AUTH_SERVICE_LOGIN_INITIATION_URI'],
          login_response_type: ENV['AUTH_SERVICE_LOGIN_RESPONSE_TYPE']
        )
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
      ENV[AUTH_SERVICE_LOGIN_INITIATION_URI]
      ENV[AUTH_SERVICE_LOGIN_RESPONSE_TYPE]
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
          is_default: is_default,
          login_initiation_uri: ENV['AUTH_SERVICE_LOGIN_INITIATION_URI'],
          login_response_type: ENV['AUTH_SERVICE_LOGIN_RESPONSE_TYPE']
        )
      end
    end
  end

  namespace :identity_provider do
    desc "registers identity_provider with id ENV[IDENTITY_PROVIDER_ID]
    to authentication service with id ENV[AUTH_SERVICE_ID].
    this will fail if
      ENV variables are not provided
      identified authentication_service or identity_provider do not exist
      the authentication_service already has a different registered identity_provider\n"
    task register: :environment do
      auth_service_id = ENV['AUTH_SERVICE_ID']
      identity_provider_id = ENV['IDENTITY_PROVIDER_ID']
      raise 'ENV[AUTH_SERVICE_ID] and ENV[IDENTITY_PROVIDER_ID] are required' unless( auth_service_id && identity_provider_id )

      auth_service = AuthenticationService.find_by(id: auth_service_id)
      raise 'authentication_service does not exist' unless auth_service
      if auth_service.identity_provider && auth_service.identity_provider_id == identity_provider_id.to_i
        $stderr.puts "AUTH_SERVICE_ID already registered with IDENTITY_PROVIDER_ID"
      else
        identity_provider = IdentityProvider.find_by(id: identity_provider_id.to_i)
        raise 'identity_provider does not exist' unless identity_provider

        if auth_service.identity_provider.nil?
          auth_service.identity_provider = identity_provider
          if auth_service.save
            $stderr.puts "finished"
          else
            raise "Unknown error #{auth_service.errors.messages}"
          end
        else
          raise "AUTH_SERVICE_ID service is registered to a different identity_provider, use auth_service:identity_provider:remove"
        end
      end
    end
    desc "removes identity_provider from authentication service
    with id ENV[AUTH_SERVICE_ID].
    this will fail if
      ENV variable is not provided
      identified authentication_service does not exist\n"
    task remove: :environment do
      auth_service_id = ENV['AUTH_SERVICE_ID']
      raise 'ENV[AUTH_SERVICE_ID] is required' unless auth_service_id

      auth_service = AuthenticationService.find_by(id: auth_service_id)
      raise 'authentication_service does not exist' unless auth_service

      if auth_service.identity_provider
        if auth_service.update(identity_provider_id: nil)
          $stderr.puts "finished"
        else
          raise "Unknown error #{auth_service.errors.messages}"
        end
      end
    end
  end
end
