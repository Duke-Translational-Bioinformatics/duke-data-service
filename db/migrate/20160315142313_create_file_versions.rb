class CreateFileVersions < ActiveRecord::Migration
  def change
    create_table :file_versions, id: :uuid do |t|
      t.uuid :data_file_id
      t.integer :version
      t.string :label
      t.uuid :upload_id
      t.uuid :creator_id
      t.boolean :is_deleted, default: false

      t.timestamps null: false
    end
  end
end
