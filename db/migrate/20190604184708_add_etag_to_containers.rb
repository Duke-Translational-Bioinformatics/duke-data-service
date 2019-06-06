class AddEtagToContainers < ActiveRecord::Migration[5.2]
  def change
    add_column :containers, :etag, :string
  end
end
