
def purge_deleted_objects
  if ENV["PURGE_OBJECTS"]
    purge_state = 'trashbin_migration'
    Project.where(is_deleted: true).find_in_batches do |group|
      print "p"
      group.each do |deleted_project|
        deleted_project.create_transaction(purge_state)
        deleted_project.force_purgation = true
        deleted_project.manage_deletion
        deleted_project.manage_children
        print '.'
      end
    end

    Folder.where(is_deleted: true, is_purged: false).find_in_batches do |group|
      print 'f'
      group.each do |deleted_folder|
        unless deleted_folder.project.is_deleted? || (deleted_folder.parent && deleted_folder.parent.is_deleted?)
          deleted_folder.create_transaction(purge_state)
          deleted_folder.update(is_deleted: true, is_purged: true)
        end
        print '.'
      end
    end

    DataFile.where(is_deleted: true, is_purged: false).find_in_batches do |group|
      print 'd'
      group.each do |deleted_file|
        unless deleted_file.project.is_deleted? || (deleted_file.parent && deleted_file.parent.is_deleted?)
          deleted_file.create_transaction(purge_state)
          deleted_file.update(is_deleted: true, is_purged: true)
        end
        print '.'
      end
    end
  end
end

def type_untyped_authentication_services
  default_type = "DukeAuthenticationService"
  untyped = AuthenticationService.where(type: nil)
  pre_count = untyped.count
  if pre_count > 0
    changed = untyped.update_all(type: default_type)
    $stderr.puts "#{changed} untyped authentication_services changed to #{default_type}"
  else
    $stderr.puts "0 untyped authentication_services changed"
  end
  puts "Fin!"
end

def type_untyped_storage_providers
  default_type = "SwiftStorageProvider"
  untyped = StorageProvider.where(type: nil)
  pre_count = untyped.count
  if pre_count > 0
    changed = untyped.update_all(type: default_type)
    $stderr.puts "#{changed} untyped storage_providers changed to #{default_type}"
  else
    $stderr.puts "0 untyped storage_providers changed"
  end
  puts "Fin!"
end

def fill_new_authentication_service_attributes
  if ENV["AUTH_SERVICE_SERVICE_ID"]
    new_attributes = [
      :login_initiation_uri,
      :login_response_type,
      :client_id
    ]

    auth_service = AuthenticationService.find_by(service_id: ENV["AUTH_SERVICE_SERVICE_ID"])
    if auth_service
      needs_update = false
      new_attributes.each do |new_attribute|
        raise "ENV[AUTH_SERVICE_#{new_attribute.to_s.upcase}] is missing!" unless ENV["AUTH_SERVICE_#{new_attribute.to_s.upcase}"]
        needs_update = auth_service.send(new_attribute).nil?
      end

      if needs_update
        auth_service.update!(
          Hash[new_attributes.map{|a| [a, ENV["AUTH_SERVICE_#{a.to_s.upcase}"]] }]
        )
        $stderr.puts "authentication_service #{ENV["AUTH_SERVICE_SERVICE_ID"]} missing_attributes updated"
      else
        $stderr.puts "authentication_service #{ENV["AUTH_SERVICE_SERVICE_ID"]} attributes do not need to be updated"
      end
    else
      raise "AUTH_SERVICE_SERVICE_ID is not a registered service"
    end
  end
end

def create_missing_fingerprints
  fingerprint_count = Fingerprint.count
  failures = []
  uploads = Upload.eager_load(:fingerprints).where('fingerprints.id is NULL').where.not(fingerprint_value: nil, completed_at: nil).unscope(:order)
  puts "Creating fingerprints for #{uploads.count} uploads"

  uploads.find_in_batches do |upload_batch|
    upload_batch.each do |u|
      ActiveRecord::Base.transaction do
        Audited.audit_class.as_user(u.audits.last.user) do
            u.fingerprints.build(
              value: u.fingerprint_value,
              algorithm: u.fingerprint_algorithm.downcase
            )
            if u.save
              print '.'
            else
              print 'F'
              failures << u
            end
        end
      end
    end
  end
  puts "#{Fingerprint.count - fingerprint_count} fingerprints created."
  unless failures.empty?
    puts "Failures!  :("
    failures.each do |upload|
      message = upload.errors.full_messages
      message << upload.fingerprints.collect {|f| f.errors.full_messages}
      puts "Upload [#{upload.id}]: #{message}"
    end
  end
  puts "Fin!"
end

def migrate_nil_consistency_status
  storage_provider = StorageProvider.first
  updated_projects = 0
  updated_uploads = 0
  projects = Project.where(is_consistent: nil).where.not(is_deleted: true)
  puts "#{projects.count} projects with nil consistency_status."
  projects.find_in_batches do |project_batch|
    project_batch.each do |p|
      if storage_provider.get_container_meta(p.id)
        p.update_columns(is_consistent: true)
      else
        p.update_columns(is_consistent: false)
      end
      print '.'
      updated_projects += 1
    end
  end
  puts "#{updated_projects} projects updated."

  uploads = Upload.where(is_consistent: nil)
  puts "#{uploads.count} uploads with nil consistency_status."
  uploads.find_in_batches do |upload_batch|
    upload_batch.each do |u|
      begin
        if storage_provider.get_object_metadata(u.project.id, u.id)
          u.update_columns(is_consistent: true)
        end
      rescue StorageProviderException
        u.update_columns(is_consistent: false)
      end
      updated_uploads += 1
      print '.'
    end
  end
  puts "#{updated_uploads} uploads updated."
end

def migrate_nil_storage_container
  updated_uploads = 0
  updated_uploads = Upload.where(storage_container: nil).update_all('storage_container = project_id')
  puts "#{updated_uploads} uploads updated"
end

def migrate_storage_provider_chunk_environment
  bad_storage_providers = StorageProvider.where(
    chunk_max_size_bytes: nil,
    chunk_max_number: nil
  )

  if bad_storage_providers.count > 0
    if (ENV['SWIFT_CHUNK_MAX_NUMBER'] && ENV['SWIFT_CHUNK_MAX_SIZE_BYTES'])
      bad_storage_providers.each do |bad_storage_provider|
        bad_storage_provider.update(
          chunk_max_size_bytes: ENV['SWIFT_CHUNK_MAX_SIZE_BYTES'],
          chunk_max_number: ENV['SWIFT_CHUNK_MAX_NUMBER']
        )
      end
    else
      $stderr.puts 'please set ENV[SWIFT_CHUNK_MAX_NUMBER] AND ENV[SWIFT_CHUNK_MAX_SIZE_BYTES]'
    end
  end
end

def populate_nil_project_slugs
  Project.paginates_per 500
  slug_count = 0
  puts 'Populate Project slugs:'
  slugless_projects = Project.where(slug: nil).unscope(:order).order('is_deleted ASC').order('created_at ASC')
  (1 .. slugless_projects.page.total_pages).each do |page_num|
    slugless_projects.page(page_num).each do |p|
      p.generate_slug
      p.save
      slug_count += 1
      print '.'
    end
  end
  puts " #{slug_count} Project slugs populated."
end

namespace :db do
  namespace :data do
    desc "Migrate existing data to fit current business rules"
    task migrate: :environment do
      Rails.logger.level = 3 unless Rails.env == 'test'
      create_missing_fingerprints
      type_untyped_authentication_services
      type_untyped_storage_providers
      migrate_nil_consistency_status
      migrate_nil_storage_container
      migrate_storage_provider_chunk_environment
      purge_deleted_objects
      populate_nil_project_slugs
    end
  end
end
