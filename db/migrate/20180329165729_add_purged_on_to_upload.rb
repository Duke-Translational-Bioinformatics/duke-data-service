class AddPurgedOnToUpload < ActiveRecord::Migration[5.1]
  def change
    add_column :uploads, :purged_on, :datetime
  end
end
