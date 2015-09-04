class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_login_at, :datetime
    add_column :users, :username, :string
  end
end
