class AddCreatorIdToUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :uploads, :creator_id, :uuid
  end
end
