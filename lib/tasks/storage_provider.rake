def configure_storage_provider(sp)
  begin
    $stderr.puts "Configuring"
    sp.configure
  rescue StorageProviderException => e
    $stderr.puts "Could not configure storage_provider #{e.message}"
  end
end

def create_swift_storage_provider
  if ENV['SWIFT_ACCT']
    unless SwiftStorageProvider.where(name: ENV['SWIFT_ACCT']).exists?
      sp = SwiftStorageProvider.create(
        display_name: ENV['SWIFT_DISPLAY_NAME'],
        description: ENV['SWIFT_DESCRIPTION'],
        name: ENV['SWIFT_ACCT'],
        url_root: ENV['SWIFT_URL_ROOT'],
        provider_version: ENV['SWIFT_VERSION'],
        auth_uri: ENV['SWIFT_AUTH_URI'],
        service_user: ENV["SWIFT_USER"],
        service_pass: ENV['SWIFT_PASS'],
        primary_key: ENV['SWIFT_PRIMARY_KEY'],
        secondary_key: ENV['SWIFT_SECONDARY_KEY'],
        chunk_hash_algorithm: (ENV['SWIFT_CHUNK_HASH_ALGORITHM'] || 'md5'),
        chunk_max_number: ENV['SWIFT_CHUNK_MAX_NUMBER'],
        chunk_max_size_bytes: ENV['SWIFT_CHUNK_MAX_SIZE_BYTES']
      )
      if sp.valid?
        configure_storage_provider(sp)
      else
        $stderr.puts "Validation Error: #{ sp.errors.to_json }"
      end
    end
  else
    $stderr.puts "YOU DO NOT HAVE YOUR SWIFT ENVIRONMENT VARIABLES SET"
  end
end

namespace :storage_provider do
  desc "creates a storage_provider using ENV"
  task create: :environment do
    supported_storage_provider_types = %w(
      swift
    )
    if ENV['STORAGE_PROVIDER_TYPE']
      if supported_storage_provider_types.include?(ENV['STORAGE_PROVIDER_TYPE'].downcase)
        create_swift_storage_provider
      else
        $stderr.puts "STORAGE_PROVIDER_TYPE must be one of #{supported_storage_provider_types.join(' ')}"
      end
    else
      $stderr.puts "YOU MUST SET ENV[STORAGE_PROVIDER_TYPE] with one of #{supported_storage_provider_types.join(' ')}"
    end
  end
end
