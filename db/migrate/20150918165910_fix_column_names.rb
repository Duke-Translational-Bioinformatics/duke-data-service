class FixColumnNames < ActiveRecord::Migration
  def change
    rename_column :data_files, :parent_id, :folder_id
    rename_column :folders, :parent_id, :folder_id
  end
end
