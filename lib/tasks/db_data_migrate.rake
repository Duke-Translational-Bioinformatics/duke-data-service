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
  #uploads = Upload.where.not(fingerprint_value: nil)
  uploads = Upload.eager_load(:fingerprints).where('fingerprints.id is NULL').where.not(fingerprint_value: nil, completed_at: nil).unscope(:order)
  fingerprint_count = Fingerprint.count
  failures = []
  puts "Creating fingerprints for #{uploads.count} uploads"
  uploads.each do |u|
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

namespace :db do
  namespace :data do
    desc "Migrate existing data to fit current business rules"
    task migrate: :environment do
      Rails.logger.level = 3 unless Rails.env == 'test'
      create_missing_fingerprints
      type_untyped_authentication_services
    end
  end
end
