class CreateProjectStorageProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :project_storage_providers, id: :uuid do |t|
      t.uuid :project_id
      t.uuid :storage_provider_id
      t.boolean :is_initialized

      t.timestamps
    end
  end
end
