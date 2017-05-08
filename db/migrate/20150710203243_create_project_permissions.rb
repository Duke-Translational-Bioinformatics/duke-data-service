class CreateProjectPermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :project_permissions, id: :uuid do |t|
      t.uuid :project_id
      t.uuid :user_id
      t.string :auth_role_id

      t.timestamps null: false
    end
  end
end
