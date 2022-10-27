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

def create_s3_storage_provider
  if ENV['S3_ACCT']
    unless S3StorageProvider.where(name: ENV['S3_ACCT']).exists?
      sp = S3StorageProvider.create(
        display_name: ENV['S3_DISPLAY_NAME'],
        description: ENV['S3_DESCRIPTION'],
        name: ENV['S3_ACCT'],
        url_root: ENV['S3_URL_ROOT'],
        service_user: ENV["S3_USER"],
        service_pass: ENV['S3_PASS']
      )
      if sp.valid?
        configure_storage_provider(sp)
      else
        $stderr.puts "Validation Error: #{ sp.errors.to_json }"
      end
    end
  else
    $stderr.puts "YOU DO NOT HAVE YOUR S3 ENVIRONMENT VARIABLES SET"
  end
end

def create_single_bucket_s3_storage_provider
  if ENV['SINGLE_BUCKET_S3_ACCT']
    unless SingleBucketS3StorageProvider.where(name: ENV['SINGLE_BUCKET_S3_ACCT']).exists?
      sp = SingleBucketS3StorageProvider.create(
        display_name: ENV['SINGLE_BUCKET_S3_DISPLAY_NAME'],
        description: ENV['SINGLE_BUCKET_S3_DESCRIPTION'],
        name: ENV['SINGLE_BUCKET_S3_ACCT'],
        bucket_name: ENV['SINGLE_BUCKET_S3_BUCKET_NAME'],
        service_user: ENV['SINGLE_BUCKET_S3_USER'],
        service_pass: ENV['SINGLE_BUCKET_S3_PASS']
      )
      if sp.valid?
        configure_storage_provider(sp)
      else
        $stderr.puts "Validation Error: #{ sp.errors.to_json }"
      end
    else
      $stderr.puts "Storage provider '#{ENV['SINGLE_BUCKET_S3_ACCT']}' already exists."
    end
  else
    $stderr.puts "YOU DO NOT HAVE YOUR SINGLE BUCKET S3 ENVIRONMENT VARIABLES SET"
  end
end

namespace :storage_provider do
  desc "creates a storage_provider using ENV"
  task create: :environment do
    supported_storage_provider_types = %w(
      swift
      s3
      single_bucket_s3
    )
    if ENV['STORAGE_PROVIDER_TYPE']
      case ENV['STORAGE_PROVIDER_TYPE'].downcase
      when 'swift'
        create_swift_storage_provider
      when 's3'
        create_s3_storage_provider
      when 'single_bucket_s3'
        create_single_bucket_s3_storage_provider
      else
        $stderr.puts "STORAGE_PROVIDER_TYPE must be one of #{supported_storage_provider_types.join(' ')}"
      end
    else
      $stderr.puts "YOU MUST SET ENV[STORAGE_PROVIDER_TYPE] with one of #{supported_storage_provider_types.join(' ')}"
    end
  end
end
