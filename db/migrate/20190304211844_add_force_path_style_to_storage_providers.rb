class AddForcePathStyleToStorageProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :storage_providers, :force_path_style, :boolean
  end
end
