namespace :storage_provider do
  desc "creates a storage_provider using ENV[SWIFT_ACCT,SWIFT_URL_ROOT,SWIFT_VERSION,SWIFT_AUTH_URI,SWIFT_USER,SWIFT_PASS,SWIFT_PRIMARY_KEY,SWIFT_SECONDARY_KEY]"
  task create: :environment do
    unless ENV['SWIFT_ACCT']
      $stderr.puts "YOU DO NOT HAVE YOUR SWIFT ENVIRONMENT VARIABLES SET"
      exit
    end
    unless StorageProvider.where(name: ENV['SWIFT_ACCT']).exists?
      sp = StorageProvider.create(
        display_name: ENV['SWIFT_DISPLAY_NAME'],
        description: ENV['SWIFT_DESCRIPTION'],
        name: ENV['SWIFT_ACCT'],
        url_root: ENV['SWIFT_URL_ROOT'],
        provider_version: ENV['SWIFT_VERSION'],
        auth_uri: ENV['SWIFT_AUTH_URI'],
        service_user: ENV["SWIFT_USER"],
        service_pass: ENV['SWIFT_PASS'],
        primary_key: ENV['SWIFT_PRIMARY_KEY'],
        secondary_key: ENV['SWIFT_SECONDARY_KEY']
      )
      if sp.valid?
        begin
          $stderr.puts "Registering Keys"
          sp.register_keys
        rescue StorageProviderException => e
          $stderr.puts "Could not register storage_provider keys #{e.message}"
        end
      else
        $stderr.puts "Error: #{ sp.errors.to_json }"
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

  desc "destroys all DataFiles and Uploads, along with their swift containers, manifests, and objects (does not run in production)"
  task cleanout: :environment do
    if Rails.env.production?
      puts "does not work in production"
      exit
    end
    Rails.logger.level = 3
    Container.auditing_enabled = false
    storage_provider = StorageProvider.first
    Project.all.each do |project|
      project.data_files.each do |data_file|
        upload = data_file.upload
        #versions
        if upload
          upload.chunks.all.each do |chunk|
            begin
              storage_provider.delete_object(project.id, chunk.object_path)
              chunk.destroy
              print "c."
            rescue StorageProviderException => e
              puts "#{chunk.sub_path} object could not be deleted #{e.message}"
            end
          end
          begin
            storage_provider.delete_object_manifest(project.id, upload.object_path)
            upload.destroy if upload
            print "u."
          rescue StorageProviderException => e
            puts "#{upload.sub_path} manifest could not be deleted #{e.message}"
          end
        end
        data_file.destroy
        print "d."
      end
      begin
        storage_provider.delete_container(project.id)
        print "p."
      rescue StorageProviderException => e
        puts "#{project.id} container could not be deleted #{e.message}"
      end
    end
    puts "\n"
    puts storage_provider.get_account_info.to_json
  end

  desc 'print storage_provider usage information'
  task usage: :environment do
    sp = StorageProvider.first
    puts sp.get_account_info.to_json
  end
end
