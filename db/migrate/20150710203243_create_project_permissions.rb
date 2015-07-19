class CreateProjectPermissions < ActiveRecord::Migration
  def change
    create_table :project_permissions do |t|
      t.integer :project_id
      t.integer :user_id
      t.jsonb :auth_role_ids

      t.timestamps null: false
    end

    add_index :project_permissions, :auth_role_ids, using: :gin
  end
end
