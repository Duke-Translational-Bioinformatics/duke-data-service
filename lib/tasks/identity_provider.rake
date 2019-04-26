namespace :identity_provider do
  desc "destroy identity_provider using ENV[IDENTITY_PROVIDER_ID]\nfails if any authentication_service is registered to the identity_provider\n"
  task destroy: :environment do
    raise "ENV\[IDENTITY_PROVIDER_ID\] is required" unless ENV['IDENTITY_PROVIDER_ID']
    identity_provider = IdentityProvider.find_by(id: ENV['IDENTITY_PROVIDER_ID'])
    if identity_provider
      if AuthenticationService.where(identity_provider_id: identity_provider.id).exists?
        raise "identity_provider is registered to one or more authentication_services. use auth_service:identity_provider:remove"
      end
      identity_provider.destroy
    end
  end

  namespace :ldap do
    desc "creates an ldap identity_provider using\n  ENV[IDENTITY_PROVIDER_HOST]\n  ENV[IDENTITY_PROVIDER_PORT]\n  ENV[IDENTITY_PROVIDER_LDAP_BASE]\nfails if environment variables not provided\n"
    task create: :environment do
      unless ENV['IDENTITY_PROVIDER_HOST'] &&
             ENV['IDENTITY_PROVIDER_PORT'] &&
             ENV['IDENTITY_PROVIDER_LDAP_BASE']
        raise "ENV\[IDENTITY_PROVIDER_HOST\], ENV\[IDENTITY_PROVIDER_PORT\], and ENV\[IDENTITY_PROVIDER_LDAP_BASE\] are required"
      end

      unless LdapIdentityProvider.where(
        host: ENV['IDENTITY_PROVIDER_HOST'],
        port: ENV['IDENTITY_PROVIDER_PORT'],
        ldap_base: ENV['IDENTITY_PROVIDER_LDAP_BASE']
      ).exists?
        LdapIdentityProvider.create!(
          host: ENV['IDENTITY_PROVIDER_HOST'],
          port: ENV['IDENTITY_PROVIDER_PORT'],
          ldap_base: ENV['IDENTITY_PROVIDER_LDAP_BASE']
        )
      end
    end
  end
end
