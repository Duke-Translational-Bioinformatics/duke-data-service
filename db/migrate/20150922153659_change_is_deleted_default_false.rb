class ChangeIsDeletedDefaultFalse < ActiveRecord::Migration
  def change
    change_column :projects, :is_deleted, :boolean, :default => false
    change_column :folders, :is_deleted, :boolean, :default => false
    change_column :data_files, :is_deleted, :boolean, :default => false
  end
end
