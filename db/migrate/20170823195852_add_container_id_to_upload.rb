class AddContainerIdToUpload < ActiveRecord::Migration[5.0]
  def change
    add_column :uploads, :container_id, :uuid
  end
end
