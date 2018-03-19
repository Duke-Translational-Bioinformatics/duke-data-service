class AddIsPurgedToContainersFileVersions < ActiveRecord::Migration[5.0]
  def change
    add_column :containers, :is_purged, :boolean, default: false
    add_column :file_versions, :is_purged, :boolean, default: false
  end
end
