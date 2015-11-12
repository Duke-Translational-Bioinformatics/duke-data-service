class RemoveAuthRoleIdsFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :auth_role_ids, :jsonb
  end
end
