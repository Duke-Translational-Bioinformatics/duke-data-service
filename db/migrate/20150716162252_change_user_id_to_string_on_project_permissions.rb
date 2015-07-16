class ChangeUserIdToStringOnProjectPermissions < ActiveRecord::Migration
  def change
    change_column :project_permissions, :user_id, :string
  end
end
