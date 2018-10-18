class AddStorageProviderToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :storage_provider_id, :uuid
  end
end
