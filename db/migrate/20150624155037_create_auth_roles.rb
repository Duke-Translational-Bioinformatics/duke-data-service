class CreateAuthRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :auth_roles, id: false do |t|
      t.string :id, null: false
      t.string :name
      t.string :description
      t.jsonb :permissions
      t.jsonb :contexts
      t.boolean :is_deprecated, null: false, default: false

      t.timestamps null: false
    end

    add_index :auth_roles, :permissions, using: :gin
    add_index :auth_roles, :contexts, using: :gin
  end
end
