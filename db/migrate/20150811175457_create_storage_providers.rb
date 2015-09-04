class CreateStorageProviders < ActiveRecord::Migration
  def change
    create_table :storage_providers do |t|
      t.string :name
      t.string :url_root
      t.string :provider_version
      t.string :auth_uri
      t.string :service_user
      t.string :service_pass
      t.string :primary_key
      t.string :secondary_key

      t.timestamps null: false
    end
  end
end
