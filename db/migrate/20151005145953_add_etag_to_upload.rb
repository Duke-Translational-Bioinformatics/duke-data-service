class AddEtagToUpload < ActiveRecord::Migration
  def change
    add_column :uploads, :etag, :string
  end
end
