class CreateStorageFolders < ActiveRecord::Migration
  def change
    create_table :storage_folders do |t|
      t.integer :project_id
      t.string :name
      t.text :description
      t.string :storage_service_uuid

      t.timestamps null: false
    end
  end
end
