class AddBucketNameToStorageProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :storage_providers, :bucket_name, :string
  end
end
