class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags, id: :uuid do |t|
      t.string :label
      t.string :taggable_type
      t.uuid :taggable_id

      t.timestamps null: false
    end
  end
end
