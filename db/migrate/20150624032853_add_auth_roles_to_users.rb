class AddAuthRolesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_roles, :text
  end
end
