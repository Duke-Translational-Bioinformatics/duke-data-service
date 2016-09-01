def create_current_file_versions
  files = DataFile.eager_load(:file_versions).unscope(:order).joins('LEFT OUTER JOIN file_versions B ON B.data_file_id = containers.id AND B.version_number > file_versions.version_number').where('B.data_file_id IS NULL').where('file_versions.data_file_id IS NULL OR containers.upload_id != file_versions.upload_id')
  version_count = FileVersion.count
  puts "Updating current_file_version for #{files.count} files"
  ActiveRecord::Base.transaction do
    files.each do |f|
      Audited.audit_class.as_user(f.audits.last.user) do
        f.save!
      end
      print "."
    end
  end
  puts "#{FileVersion.count - version_count} versions created."
  puts "Fin!"
end

def create_missing_fingerprints
  #uploads = Upload.where.not(fingerprint_value: nil)
  uploads = Upload.eager_load(:fingerprints).where('fingerprints.id is NULL').where.not(fingerprint_value: nil).unscope(:order)
  fingerprint_count = Fingerprint.count
  failures = []
  puts "Creating fingerprints for #{uploads.count} uploads"
  ActiveRecord::Base.transaction do
    uploads.each do |u|
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
      create_current_file_versions
      create_missing_fingerprints
    end
  end
end
