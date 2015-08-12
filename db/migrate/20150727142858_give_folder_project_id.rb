class GiveFolderProjectId < ActiveRecord::Migration
  def change
    add_column :folders, :project_id, :string
  end
end
