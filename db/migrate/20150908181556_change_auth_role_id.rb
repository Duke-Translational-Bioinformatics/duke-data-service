class ChangeAuthRoleId < ActiveRecord::Migration
  def up
    drop_table :auth_roles
    create_table :auth_roles, id: false do |t|
      t.string :id, null: false
      t.string :name
      t.string :description
      t.jsonb :permissions
      t.jsonb :contexts
      t.boolean :is_deprecated

      t.timestamps null: false
    end

    add_index :auth_roles, :permissions, using: :gin
    add_index :auth_roles, :contexts, using: :gin

    change_column :project_permissions, :auth_role_id, :string
  end

  def down
    drop_table :auth_roles
    create_table :auth_roles do |t|
      t.string :text_id
      t.string :name
      t.string :description
      t.jsonb :permissions
      t.jsonb :contexts
      t.boolean :is_deprecated

      t.timestamps null: false
    end

    add_index :auth_roles, :permissions, using: :gin
    add_index :auth_roles, :contexts, using: :gin
    change_column :project_permissions, :auth_role_id, :integer
  end
end
