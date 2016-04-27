class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities, id: :uuid do |t|
      t.string :name
      t.string :description
      t.uuid :creator_id
      t.datetime :started_on
      t.datetime :ended_on
      t.boolean :is_deleted

      t.timestamps null: false
    end
  end
end
