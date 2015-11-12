class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects, id: :uuid do |t|
      t.string :name
      t.string :description
      t.integer :creator_id
      t.string :etag
      t.boolean :is_deleted, :default => false

      t.timestamps null: false
    end
  end
end
