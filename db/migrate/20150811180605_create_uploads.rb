class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads, id: :uuid do |t|
      t.uuid :project_id
      t.string :name
      t.string :content_type
      t.integer :size
      t.string :fingerprint_value
      t.string :fingerprint_algorithm
      t.integer :storage_provider_id

      t.timestamps null: false
    end
  end
end
