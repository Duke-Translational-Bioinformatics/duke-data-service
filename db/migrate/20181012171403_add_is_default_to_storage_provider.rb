class AddIsDefaultToStorageProvider < ActiveRecord::Migration[5.1]
  def change
    add_column :storage_providers, :is_default, :boolean
  end
end
