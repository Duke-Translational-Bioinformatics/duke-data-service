class AddDeletedFromParentToContainers < ActiveRecord::Migration[5.1]
  def change
    add_column :containers, :deleted_from_parent_id, :uuid
  end
end
