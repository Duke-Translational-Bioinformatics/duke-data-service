class CreateStorageProviders < ActiveRecord::Migration[4.2]
  def change
    create_table :storage_providers, id: :uuid do |t|
      t.string :display_name
      t.string :description
      t.string :name
      t.string :url_root
      t.string :provider_version
      t.string :auth_uri
      t.string :service_user
      t.string :service_pass
      t.string :primary_key
      t.string :secondary_key
      t.boolean :is_deprecated, null: false, default: false

      t.timestamps null: false
    end
  end
end
