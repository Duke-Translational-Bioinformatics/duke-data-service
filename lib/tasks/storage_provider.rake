namespace :storage_provider do
  desc "creates a storage_provider using ENV[SWIFT_ACCT,SWIFT_URL_ROOT,SWIFT_VERSION,SWIFT_AUTH_URI,SWIFT_USER,SWIFT_PASS,SWIFT_PRIMARY_KEY,SWIFT_SECONDARY_KEY]"
  task create: :environment do
    unless ENV['SWIFT_ACCT']
      $stderr.puts "YOU DO NOT HAVE YOUR SWIFT ENVIRONMENT VARIABLES SET"
      exit
    end
    unless StorageProvider.where(name: ENV['SWIFT_ACCT']).exists?
      sp = StorageProvider.create(
        name: ENV['SWIFT_ACCT'],
        url_root: ENV['SWIFT_URL_ROOT'],
        provider_version: ENV['SWIFT_VERSION'],
        auth_uri: ENV['SWIFT_AUTH_URI'],
        service_user: ENV["SWIFT_USER"],
        service_pass: ENV['SWIFT_PASS'],
        primary_key: ENV['SWIFT_PRIMARY_KEY'],
        secondary_key: ENV['SWIFT_SECONDARY_KEY']
      )
      begin
        $stderr.puts "Registering Keys #{sp.to_json}"
        $stderr.puts "ACCT INFO #{ sp.get_account_info.to_json }"
        sp.register_keys
      rescue StorageProviderException => e
        $stderr.puts "Could not register storage_provider keys #{e.message}"
      end
    end
  end

  desc "destroys the storage_provider defined for ENV[SWIFT_ACCT]"
  task destroy: :environment do
    storage_provider = StorageProvider.where(name: ENV['SWIFT_ACCT']).first
    if storage_provider
      storage_provider.destroy
    end
  end
end
