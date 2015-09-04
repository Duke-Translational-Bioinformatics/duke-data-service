class CreateChunks < ActiveRecord::Migration
  def change
    create_table :chunks do |t|
      t.uuid :upload_id
      t.integer :number
      t.integer :size
      t.string :fingerprint_value
      t.string :fingerprint_algorithm

      t.timestamps null: false
    end
  end
end
