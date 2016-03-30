class RenameVersionToVersionNumberOnFileVersions < ActiveRecord::Migration
  def change
    rename_column :file_versions, :version, :version_number
  end
end
