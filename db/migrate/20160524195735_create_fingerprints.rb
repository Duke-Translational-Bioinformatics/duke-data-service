class CreateFingerprints < ActiveRecord::Migration[4.2]
  def change
    create_table :fingerprints, id: :uuid do |t|
      t.uuid :upload_id
      t.string :algorithm
      t.string :value

      t.timestamps null: false
    end
  end
end
