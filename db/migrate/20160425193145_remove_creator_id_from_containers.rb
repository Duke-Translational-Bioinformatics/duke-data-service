class RemoveCreatorIdFromContainers < ActiveRecord::Migration[4.2]
  def change
    remove_column :containers, :creator_id, :uuid
  end
end
