class RecreateMetaProperties < ActiveRecord::Migration[4.2]
  def change
    drop_table :meta_properties
    create_table :meta_properties, id: :uuid do |t|
      t.uuid :meta_template_id
      t.uuid :property_id
      t.string :value

      t.timestamps null: false
    end
  end
end
