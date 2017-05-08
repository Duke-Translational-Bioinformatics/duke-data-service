class CreateProjects < ActiveRecord::Migration[4.2]
  def change
    create_table :projects, id: :uuid do |t|
      t.string :name
      t.string :description
      t.uuid :creator_id
      t.string :etag
      t.boolean :is_deleted, :default => false

      t.timestamps null: false
    end
  end
end
