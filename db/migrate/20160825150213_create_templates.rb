class CreateTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :templates, id: :uuid do |t|
      t.string :name
      t.string :label
      t.text :description
      t.boolean :is_deprecated, default: false
      t.uuid :creator_id

      t.timestamps null: false
    end
  end
end
