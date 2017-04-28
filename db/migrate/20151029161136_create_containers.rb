class CreateContainers < ActiveRecord::Migration[4.2]
  def change
    create_table :containers, id: :uuid do |t|
      t.string :name
      t.string :type
      t.uuid :parent_id
      t.uuid :project_id
      t.uuid :creator_id
      t.uuid :upload_id
      t.boolean :is_deleted, default: false

      t.timestamps null: false
    end
  end
end
