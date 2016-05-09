class CreateProvRelations < ActiveRecord::Migration
  def change
    create_table :prov_relations, id: :uuid do |t|
      t.string :type #sti
      t.uuid :creator_id
      t.uuid :relatable_from_id
      t.string :relatable_from_type

      t.string :relationship_type

      t.uuid :relatable_to_id
      t.string :relatable_to_type

      t.boolean :is_deleted, :default => false

      t.timestamps null: false
    end
    add_index :prov_relations, :relatable_from_id
    add_index :prov_relations, :relatable_to_id
  end
end
