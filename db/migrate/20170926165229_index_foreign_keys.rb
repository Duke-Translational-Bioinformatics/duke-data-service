class IndexForeignKeys < ActiveRecord::Migration[5.0]
  def change
    add_index(:containers, :parent_id)
    add_index(:containers, :project_id)
    add_index(:containers, [:id, :type])
    add_index(:containers, [:project_id, :parent_id, :is_deleted])
    add_index(:file_versions, :data_file_id)
    add_index(:fingerprints, :upload_id)
    add_index(:chunks, :upload_id)
    add_index(:chunks, [:upload_id, :number])
    add_index(:project_permissions, [:project_id, :auth_role_id, :user_id],
              name: 'index_project_permissions_on_project_and_auth_role_and_user')
  end
end
