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

namespace :db do
  namespace :data do
    desc "Migrate existing data to fit current business rules"
    task migrate: :environment do
      create_current_file_versions
    end
  end
end
