class AddStorageContainerToUpload < ActiveRecord::Migration[5.0]
  def change
    add_column :uploads, :storage_container, :string
  end
end
