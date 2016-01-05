class CreateSystemPermissions < ActiveRecord::Migration
  def change
    create_table :system_permissions, id: :uuid do |t|
      t.uuid :user_id
      t.string :auth_role_id

      t.timestamps null: false
    end
  end
end
