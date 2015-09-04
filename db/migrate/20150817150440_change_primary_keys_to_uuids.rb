class ChangePrimaryKeysToUuids < ActiveRecord::Migration
  def change
    drop_table :users
    create_table :users, id: :uuid  do |t|
      t.string :etag
      t.string :email
      t.string :display_name
      t.jsonb :auth_role_ids
      t.string :first_name
      t.string :last_name

      t.timestamps null: false
    end

    drop_table :projects
    create_table :projects, id: :uuid  do |t|
      t.string :name
      t.string :description
      t.uuid :creator_id
      t.string :etag
      t.boolean :is_deleted

      t.timestamps null: false
    end

    drop_table :memberships
    create_table :memberships, id: :uuid  do |t|
      t.uuid :user_id
      t.uuid :project_id

      t.timestamps null: false
    end

    remove_column :folders, :project_id, :string
    add_column :folders, :project_id, :uuid
    remove_column :project_permissions, :user_id, :string
    add_column :project_permissions, :user_id, :uuid
    remove_column :project_permissions, :project_id, :string
    add_column :project_permissions, :project_id, :uuid
    remove_column :storage_folders, :project_id, :string
    add_column :storage_folders, :project_id, :uuid
    remove_column :user_authentication_services, :user_id, :string
    add_column :user_authentication_services, :user_id, :uuid
  end
end
