class AddTypeToUploads < ActiveRecord::Migration[5.2]
  def change
    add_column :uploads, :type, :string
  end
end
