class AddAuthRoleIdToProjectPermissions < ActiveRecord::Migration
  def change
    add_column :project_permissions, :auth_role_id, :integer
  end
end
