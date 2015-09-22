class FixColumnNamesAgain < ActiveRecord::Migration
  def change
    rename_column :data_files, :folder_id, :parent_id
    rename_column :folders, :folder_id, :parent_id
  end
end
