class RemoveAuthRoleIdsFromProjectPermissions < ActiveRecord::Migration
  def change
    remove_column :project_permissions, :auth_role_ids, :jsonb
  end
end
