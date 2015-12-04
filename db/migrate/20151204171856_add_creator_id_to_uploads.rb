class AddCreatorIdToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :creator_id, :uuid
  end
end
