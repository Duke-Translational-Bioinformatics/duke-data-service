class AddIsDeletedBooleanToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :is_deleted, :boolean
  end
end
