class CreateAuthRoles < ActiveRecord::Migration
  def change
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
  end
end
