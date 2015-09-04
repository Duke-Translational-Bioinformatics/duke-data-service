class CreateFolders < ActiveRecord::Migration
  def up
    enable_extension 'uuid-ossp'
    create_table :folders, id: :uuid  do |t|
      t.string :name
      t.uuid :parent_id
      t.string :project_id
      t.boolean :is_deleted

      t.timestamps null: false
    end
  end

  def down
    drop_table :folders
  end

end
