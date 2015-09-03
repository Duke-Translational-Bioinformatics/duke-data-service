class CreateDataFiles < ActiveRecord::Migration
  def up
    enable_extension 'uuid-ossp'
    create_table :data_files, id: :uuid do |t|
      t.string :name
      t.uuid :upload_id
      t.uuid :parent_id
      t.uuid :project_id
      t.uuid :creator_id
      t.boolean :is_deleted

      t.timestamps null: false
    end
  end

  def down
    drop_table :data_files
  end
end
