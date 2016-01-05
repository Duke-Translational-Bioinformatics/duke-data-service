class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads, id: :uuid do |t|
      t.uuid :project_id
      t.string :name
      t.string :content_type
      t.integer :size
      t.string :fingerprint_value
      t.string :fingerprint_algorithm
      t.uuid :storage_provider_id
      t.datetime :error_at
      t.string :error_message
      t.datetime :completed_at
      t.string :etag

      t.timestamps null: false
    end
  end
end
