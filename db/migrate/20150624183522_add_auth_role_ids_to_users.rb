class AddAuthRoleIdsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_role_ids, :jsonb
    add_index :users, :auth_role_ids, using: :gin
  end
end
