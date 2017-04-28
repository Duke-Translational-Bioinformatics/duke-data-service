class RenameVersionToVersionNumberOnFileVersions < ActiveRecord::Migration[4.2]
  def change
    rename_column :file_versions, :version, :version_number
  end
end
