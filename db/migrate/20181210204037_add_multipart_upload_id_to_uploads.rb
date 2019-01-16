class AddMultipartUploadIdToUploads < ActiveRecord::Migration[5.1]
  def change
    add_column :uploads, :multipart_upload_id, :string
  end
end
