class AddUuidAndDisplayNameAndDescriptionAndIsDeprecatedToStorageProvider < ActiveRecord::Migration
  def change
    drop_table :storage_providers
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
      t.boolean :is_deprecated

      t.timestamps null: false
    end
    remove_column :uploads, :storage_provider_id, :integer
    add_column :uploads, :storage_provider_id, :uuid
  end
end
