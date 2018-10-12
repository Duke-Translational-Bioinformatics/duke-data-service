class AddTypeToStorageProvider < ActiveRecord::Migration[5.1]
  def change
    add_column :storage_providers, :type, :string
  end
end
