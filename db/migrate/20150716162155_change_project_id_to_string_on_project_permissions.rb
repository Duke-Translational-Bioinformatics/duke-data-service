class ChangeProjectIdToStringOnProjectPermissions < ActiveRecord::Migration
  def change
    change_column :project_permissions, :project_id, :string
  end
end
