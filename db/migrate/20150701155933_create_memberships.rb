class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer :user_id
      t.string :project_id

      t.timestamps null: false
    end
  end
end
