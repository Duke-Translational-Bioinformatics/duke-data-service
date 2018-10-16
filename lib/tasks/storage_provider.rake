namespace :storage_provider do
  desc "creates a storage_provider using ENV[SWIFT_ACCT,SWIFT_URL_ROOT,SWIFT_VERSION,SWIFT_AUTH_URI,SWIFT_USER,SWIFT_PASS,SWIFT_PRIMARY_KEY,SWIFT_SECONDARY_KEY,SWIFT_CHUNK_HASH_ALGORITHM]"
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
        secondary_key: ENV['SWIFT_SECONDARY_KEY'],
        chunk_hash_algorithm: (ENV['SWIFT_CHUNK_HASH_ALGORITHM'] || 'md5'),
        chunk_max_number: ENV['SWIFT_CHUNK_MAX_NUMBER'],
        chunk_max_size_bytes: ENV['SWIFT_CHUNK_MAX_SIZE_BYTES']
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
    storage_provider = StorageProvider.default
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
    Rails.logger.level = 3
    sp = StorageProvider.default
    puts sp.get_account_info.to_json
  end

  desc 'destroys containers, manifests, and objects orphaned from destroyed or logically_deleted objects'
  task prune: :environment do
    Rails.logger.level = 3
    to_prune = {
      projects: [],
      uploads: [],
      chunks: []
    }

    storage_provider = StorageProvider.default
    storage_provider.get_containers.each do |container|
      unless Project.where(id: container).exists?
        to_prune[:projects] << container
      end

      storage_provider.get_container_objects(container).each do |object|
        begin
          if storage_provider.get_object_metadata(container, object)["x-static-large-object"]
            unless Upload.where(id: object).exists?
              to_prune[:uploads] << [container, object]
            end
          else
            upload_id, chunk_number = object.split('/')
            unless Chunk.where(upload_id: upload_id, number: chunk_number).exists?
              to_prune[:chunks] << [container, object]
            end
          end
        rescue StorageProviderException => e
          puts "container #{container} object #{object} returned by get_container_objects, but metadata not accessible? #{e.message}"
        end
      end
    end

    to_prune[:chunks].each do |chunk|
      begin
        storage_provider.delete_object(*chunk)
        print 'c.'
      rescue StorageProviderException => e
        puts "#{chunk} object could not be deleted #{e.message}"
      end
    end
    to_prune[:uploads].each do |upload|
      begin
        storage_provider.delete_object_manifest(*upload)
        print 'u.'
      rescue StorageProviderException => e
        puts "#{object} manifest could not be deleted #{e.message}"
      end
    end
    to_prune[:projects].each do |project|
      begin
        storage_provider.delete_container(project)
        print 'p.'
      rescue StorageProviderException => e
        puts "#{project} container could not be deleted #{e.message}"
      end
    end
  end
end
