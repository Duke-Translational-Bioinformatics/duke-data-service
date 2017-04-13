class CreateProperties < ActiveRecord::Migration[4.2]
  def change
    create_table :properties, id: :uuid do |t|
      t.uuid :template_id
      t.string :key
      t.string :label
      t.text :description
      t.string :data_type
      t.boolean :is_deprecated

      t.timestamps null: false
    end
  end
end
