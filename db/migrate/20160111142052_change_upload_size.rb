class ChangeUploadSize < ActiveRecord::Migration
  def change
    change_column :uploads, :size,  :bigint
  end
end
