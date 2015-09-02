class AddCompletedAtToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :completed_at, :datetime
  end
end
