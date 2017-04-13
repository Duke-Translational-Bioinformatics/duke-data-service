class ChangeUploadSize < ActiveRecord::Migration[4.2]
  def change
    change_column :uploads, :size,  :bigint
  end
end
