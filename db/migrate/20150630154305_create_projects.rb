class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name
      t.string :description
      t.string :uuid
      t.integer :creator_id
      t.string :etag
      t.boolean :is_deleted
      t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
