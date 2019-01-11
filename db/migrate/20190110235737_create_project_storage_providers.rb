class CreateProjectStorageProviders < ActiveRecord::Migration[5.1]
  def change
    create_table :project_storage_providers do |t|
      t.uuid :project_id
      t.uuid :storage_provider_id
      t.boolean :is_initialized

      t.timestamps
    end
  end
end
