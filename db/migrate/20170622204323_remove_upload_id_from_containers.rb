class RemoveUploadIdFromContainers < ActiveRecord::Migration[5.0]
  def change
    remove_column :containers, :upload_id, :uuid
  end
end
