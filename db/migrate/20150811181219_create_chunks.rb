class CreateChunks < ActiveRecord::Migration[4.2]
  def change
    create_table :chunks, id: :uuid do |t|
      t.uuid :upload_id
      t.integer :number
      t.integer :size
      t.string :fingerprint_value
      t.string :fingerprint_algorithm

      t.timestamps null: false
    end
  end
end
