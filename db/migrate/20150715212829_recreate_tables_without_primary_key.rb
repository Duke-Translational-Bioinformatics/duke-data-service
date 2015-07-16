class RecreateTablesWithoutPrimaryKey < ActiveRecord::Migration
  def change
    drop_table :users
    drop_table :projects
    drop_table :memberships

    create_table :users, id: false do |t|
      t.string :id, null: false
      t.string   :etag
      t.string   :email
      t.string   :display_name
      t.jsonb    :auth_role_ids
      t.string   :first_name
      t.string   :last_name

      t.timestamps null: false
    end

    add_index :users, :id, unique: true

    create_table :projects, id: false do |t|
      t.string :id, null: false
      t.string   :name
      t.string   :description
      t.string   :creator_id
      t.string   :etag
      t.boolean  :is_deleted
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :projects, :id, unique: true

    create_table :memberships, id: false do |t|
      t.string :id, null: false
      t.string   :user_id
      t.string   :project_id

      t.timestamps null: false
    end

    add_index :memberships, :id, unique: true
  end
end
