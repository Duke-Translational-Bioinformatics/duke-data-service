class RemoveCreatorIdFromContainers < ActiveRecord::Migration
  def change
    remove_column :containers, :creator_id, :uuid
  end
end
