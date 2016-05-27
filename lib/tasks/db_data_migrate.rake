def create_current_file_versions
  files = DataFile.all
  version_count = FileVersion.count
  puts "Updating current_file_version for all #{files.count} files"
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
  puts "Creating fingerprints for #{uploads.count} uploads"
  ActiveRecord::Base.transaction do
    uploads.each do |u|
      Audited.audit_class.as_user(u.audits.last.user) do
#        if u.fingerprints.empty?
          u.fingerprints.build(
            value: u.fingerprint_value,
            algorithm: u.fingerprint_algorithm
          )
          if u.save
            print '.'
          else
            print 'F'
          end
#        else
#          print 'S'
#        end
      end
    end
  end
  puts "#{Fingerprint.count - fingerprint_count} fingerprints created."
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
