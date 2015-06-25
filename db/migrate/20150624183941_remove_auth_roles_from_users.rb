class RemoveAuthRolesFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :auth_roles, :text
  end
end
